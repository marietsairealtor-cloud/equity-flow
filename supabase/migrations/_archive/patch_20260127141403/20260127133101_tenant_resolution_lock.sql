-- tenant resolution lock: profile -> dev override -> jwt(optional) -> null
-- rules:
-- - current_tenant_id() is pure/stable (no writes)
-- - mismatch is non-breaking: prefer profile, flag mismatch; no exceptions
-- - if resolved tenant is null, RLS should deny by design

-- 1) ensure a minimal log table exists (side effects are only in log_tenant_mismatch)
create table if not exists public.tenant_mismatch_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  user_id uuid not null,
  profile_tenant_id uuid null,
  jwt_tenant_id uuid null,
  context jsonb not null default '{}'::jsonb
);

alter table public.tenant_mismatch_log enable row level security;

do $plpgsql$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='tenant_mismatch_log' and policyname='tenant_mismatch_log_owner_read'
  ) then
    execute 'create policy tenant_mismatch_log_owner_read on public.tenant_mismatch_log
             for select to authenticated
             using (user_id = auth.uid())';
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname='public' and tablename='tenant_mismatch_log' and policyname='tenant_mismatch_log_owner_insert'
  ) then
    execute 'create policy tenant_mismatch_log_owner_insert on public.tenant_mismatch_log
             for insert to authenticated
             with check (user_id = auth.uid())';
  end if;
end
$plpgsql$;

-- 2) jwt-tenant enable toggle (default false)
drop function if exists public.jwt_tenant_enabled();
create function public.jwt_tenant_enabled()
returns boolean
language sql
stable
as $fn$
  select coalesce(
    nullif(lower(current_setting('app.enable_jwt_tenant', true)),'') in ('1','true','t','yes','y','on'),
    false
  );
$fn$;

-- 3) profile tenant lookup helper
drop function if exists public.profile_current_tenant_id();
create function public.profile_current_tenant_id()
returns uuid
language sql
stable
as $fn$
  select up.current_tenant_id
  from public.user_profiles up
  where up.user_id = auth.uid();
$fn$;

-- 4) jwt tenant lookup helper (returns null unless enabled + valid uuid)
drop function if exists public.jwt_current_tenant_id();
create function public.jwt_current_tenant_id()
returns uuid
language sql
stable
as $fn$
  select case
    when public.jwt_tenant_enabled() is distinct from true then null
    else nullif(auth.jwt()->>'tenant_id','')::uuid
  end;
$fn$;

-- 5) dev/test override tenant lookup helper (GUC app.tenant_id)
drop function if exists public.dev_override_tenant_id();
create function public.dev_override_tenant_id()
returns uuid
language sql
stable
as $fn$
  select nullif(current_setting('app.tenant_id', true),'')::uuid;
$fn$;

-- 6) canonical tenant resolver (PURE/STABLE): profile -> dev override -> jwt(optional) -> null
create or replace function public.current_tenant_id()
returns uuid
language sql
stable
as $fn$
  select coalesce(
    public.profile_current_tenant_id(),
    public.dev_override_tenant_id(),
    public.jwt_current_tenant_id()
  );
$fn$;

-- 7) mismatch detector (PURE): true if profile and jwt are both non-null and differ
drop function if exists public.tenant_id_mismatch();
create function public.tenant_id_mismatch()
returns boolean
language sql
stable
as $fn$
  with v as (
    select
      public.profile_current_tenant_id() as profile_tenant_id,
      public.jwt_current_tenant_id()     as jwt_tenant_id
  )
  select
    (v.profile_tenant_id is not null)
    and (v.jwt_tenant_id is not null)
    and (v.profile_tenant_id <> v.jwt_tenant_id)
  from v;
$fn$;

-- 8) explicit logger (SIDE EFFECTS OK): callable from RPC entrypoints/middleware ONLY
drop function if exists public.log_tenant_mismatch(jsonb);
create function public.log_tenant_mismatch(p_context jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_user_id uuid;
  v_profile uuid;
  v_jwt uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return;
  end if;

  v_profile := public.profile_current_tenant_id();
  v_jwt := public.jwt_current_tenant_id();

  if v_profile is not null and v_jwt is not null and v_profile <> v_jwt then
    insert into public.tenant_mismatch_log(user_id, profile_tenant_id, jwt_tenant_id, context)
    values (v_user_id, v_profile, v_jwt, coalesce(p_context,'{}'::jsonb));
  end if;
end;
$fn$;

revoke all on function public.log_tenant_mismatch(jsonb) from public;
grant execute on function public.log_tenant_mismatch(jsonb) to authenticated;

-- 9) update any helper(s) that should never rely on auth.jwt tenant directly
drop function if exists public.can_write_current_tenant();
create function public.can_write_current_tenant()
returns boolean
language sql
stable
as $fn$
  select public.tenant_write_allowed(public.current_tenant_id());
$fn$;

-- 10) enforcement helper: detect drift (policies/functions using jwt tenant_id directly)
drop function if exists public.find_jwt_tenant_refs();
create function public.find_jwt_tenant_refs()
returns table(kind text, schema_name text, object_name text, detail text)
language sql
stable
as $fn$
  (
    select
      'policy'::text as kind,
      p.schemaname as schema_name,
      (p.tablename || '.' || p.policyname) as object_name,
      coalesce(p.qual,'') || ' | ' || coalesce(p.with_check,'') as detail
    from pg_policies p
    where
      (coalesce(p.qual,'') ilike '%auth.jwt()->>''tenant_id''%'
       or coalesce(p.with_check,'') ilike '%auth.jwt()->>''tenant_id''%'
       or coalesce(p.qual,'') ilike '%auth.jwt() ->> ''tenant_id''%'
       or coalesce(p.with_check,'') ilike '%auth.jwt() ->> ''tenant_id''%')
  )
  union all
  (
    select
      'function'::text as kind,
      n.nspname as schema_name,
      p.proname as object_name,
      pg_get_functiondef(p.oid) as detail
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (pg_get_functiondef(p.oid) ilike '%auth.jwt()->>''tenant_id''%'
           or pg_get_functiondef(p.oid) ilike '%auth.jwt() ->> ''tenant_id''%')
  );
$fn$;

drop function if exists public.assert_no_jwt_tenant_refs();
create function public.assert_no_jwt_tenant_refs()
returns void
language plpgsql
stable
as $fn$
declare
  v_cnt int;
begin
  select count(*) into v_cnt from public.find_jwt_tenant_refs();
  if v_cnt > 0 then
    raise exception using
      message = 'JWT tenant_id references found in policies/functions. Replace with public.current_tenant_id(). Run: select * from public.find_jwt_tenant_refs();';
  end if;
end;
$fn$;