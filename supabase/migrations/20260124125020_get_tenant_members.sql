-- Bootstrap for fresh local DB: ensure tenant_memberships exists before creating get_tenant_members()
-- NOTE: This is ONLY to prevent migration-order failure on fresh local start.

create table if not exists public.tenant_memberships (
  tenant_id     uuid        not null,
  user_id       uuid        not null,
  role          text        not null default 'member',
  tier          text        not null default 'free',
  status        text        not null default 'pending',
  trial_ends_at timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create or replace function public.get_tenant_members(p_tenant_id uuid)
returns table(user_id uuid, email text, role text, created_at timestamptz)
language sql
stable
security definer
set search_path = public, auth
as $function$
  select
    tm.user_id,
    u.email,
    (tm.role)::text as role,
    tm.created_at
  from public.tenant_memberships tm
  join auth.users u on u.id = tm.user_id
  where tm.tenant_id = p_tenant_id
  order by tm.created_at asc;
$function$;