-- Week 2 RPCs: idempotency + row_version + audit + list/create/update
-- Clean rewrite (removes any injected "OK:" garbage). No BEGIN/COMMIT wrappers.

create table if not exists public.rpc_idempotency (
  scope text not null,
  action text not null,
  idempotency_key text not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (scope, action, idempotency_key)
);

revoke all on table public.rpc_idempotency from public;
revoke all on table public.rpc_idempotency from anon;
revoke all on table public.rpc_idempotency from authenticated;

alter table public.deals
  add column if not exists row_version int not null default 1;

alter table public.deals
  add column if not exists updated_at timestamptz not null default now();

alter table public.audit_log
  add column if not exists tenant_id uuid,
  add column if not exists user_id uuid,
  add column if not exists action text,
  add column if not exists entity text,
  add column if not exists entity_id uuid,
  add column if not exists payload jsonb;

create or replace function public._audit_write(
  p_tenant_id uuid,
  p_action text,
  p_entity text,
  p_entity_id uuid,
  p_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $plpgsql$
begin
  insert into public.audit_log (tenant_id, user_id, action, entity, entity_id, payload)
  values (p_tenant_id, auth.uid(), p_action, p_entity, p_entity_id, p_payload);
end;
$plpgsql$;

revoke all on function public._audit_write(uuid,text,text,uuid,jsonb) from public;
revoke all on function public._audit_write(uuid,text,text,uuid,jsonb) from anon;
revoke all on function public._audit_write(uuid,text,text,uuid,jsonb) from authenticated;

create or replace function public.list_deals()
returns table (
  id uuid,
  status public.deal_status,
  market_area text,
  row_version int,
  updated_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public, auth
as $fn$
  select
    d.id,
    d.status,
    d.market_area,
    d.row_version,
    d.updated_at,
    d.created_at
  from public.deals d
  where d.tenant_id = public.current_tenant_id()
  order by d.updated_at desc
  limit 100;
$fn$;

grant execute on function public.list_deals() to authenticated;

create or replace function public.create_deal(
  payload jsonb,
  idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $plpgsql$
declare
  v_tenant_id uuid;
  v_scope text;
  v_existing jsonb;
  v_deal_id uuid;
  v_row_version int;
  v_status public.deal_status;
  v_market_area text;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT_SELECTED';
  end if;

  if not public.tenant_write_allowed(v_tenant_id) then
    raise exception 'WRITE_NOT_ALLOWED';
  end if;

  if idempotency_key is null or btrim(idempotency_key) = '' then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED';
  end if;

  v_scope := v_tenant_id::text;

  select ri.result into v_existing
  from public.rpc_idempotency ri
  where ri.scope = v_scope
    and ri.action = 'create_deal'
    and ri.idempotency_key = idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;

  v_status := coalesce(nullif(payload->>'status',''), 'New')::public.deal_status;
  v_market_area := coalesce(nullif(payload->>'market_area',''), 'default');

  insert into public.deals (tenant_id, status, market_area, updated_at)
  values (v_tenant_id, v_status, v_market_area, now())
  returning id, row_version into v_deal_id, v_row_version;

  perform public._audit_write(
    v_tenant_id,
    'create_deal',
    'deals',
    v_deal_id,
    jsonb_build_object('payload', payload)
  );

  v_result := jsonb_build_object(
    'ok', true,
    'deal_id', v_deal_id,
    'row_version', v_row_version
  );

  insert into public.rpc_idempotency (scope, action, idempotency_key, result)
  values (v_scope, 'create_deal', idempotency_key, v_result);

  return v_result;
end;
$plpgsql$;

grant execute on function public.create_deal(jsonb,text) to authenticated;

create or replace function public.update_deal(
  payload jsonb,
  expected_row_version int,
  idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $plpgsql$
declare
  v_tenant_id uuid;
  v_scope text;
  v_existing jsonb;
  v_deal_id uuid;
  v_current_row_version int;
  v_new_row_version int;
  v_status public.deal_status;
  v_market_area text;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT_SELECTED';
  end if;

  if not public.tenant_write_allowed(v_tenant_id) then
    raise exception 'WRITE_NOT_ALLOWED';
  end if;

  if idempotency_key is null or btrim(idempotency_key) = '' then
    raise exception 'IDEMPOTENCY_KEY_REQUIRED';
  end if;

  v_scope := v_tenant_id::text;

  select ri.result into v_existing
  from public.rpc_idempotency ri
  where ri.scope = v_scope
    and ri.action = 'update_deal'
    and ri.idempotency_key = idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;

  v_deal_id := nullif(payload->>'id','')::uuid;
  if v_deal_id is null then
    raise exception 'DEAL_ID_REQUIRED';
  end if;

  select d.row_version into v_current_row_version
  from public.deals d
  where d.id = v_deal_id
    and d.tenant_id = v_tenant_id;

  if v_current_row_version is null then
    raise exception 'NOT_FOUND';
  end if;

  if expected_row_version is null then
    raise exception 'EXPECTED_ROW_VERSION_REQUIRED';
  end if;

  if v_current_row_version <> expected_row_version then
    raise exception 'ROW_VERSION_CONFLICT';
  end if;

  v_status := coalesce(nullif(payload->>'status',''), null)::public.deal_status;
  v_market_area := coalesce(nullif(payload->>'market_area',''), null);

  update public.deals d
  set
    status = coalesce(v_status, d.status),
    market_area = coalesce(v_market_area, d.market_area),
    row_version = d.row_version + 1,
    updated_at = now()
  where d.id = v_deal_id
    and d.tenant_id = v_tenant_id
  returning row_version into v_new_row_version;

  perform public._audit_write(
    v_tenant_id,
    'update_deal',
    'deals',
    v_deal_id,
    jsonb_build_object(
      'payload', payload,
      'expected_row_version', expected_row_version
    )
  );

  v_result := jsonb_build_object(
    'ok', true,
    'deal_id', v_deal_id,
    'row_version', v_new_row_version
  );

  insert into public.rpc_idempotency (scope, action, idempotency_key, result)
  values (v_scope, 'update_deal', idempotency_key, v_result);

  return v_result;
end;
$plpgsql$;

grant execute on function public.update_deal(jsonb,int,text) to authenticated;