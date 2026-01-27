-- Provision tenant + seed first deal (atomic, idempotent)
-- Server-authenticated (authenticated), never anon.

create or replace function public.provision_upgrade_save(
  p_workspace_name text,
  p_first_deal jsonb default '{}'::jsonb
)
returns table(tenant_id uuid, deal_id uuid)
language plpgsql
security definer
set search_path = public
as $20260123131850_001_provision_upgrade_save$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_deal_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = 'P0001';
  end if;

  -- Idempotent: if user already owns a tenant, reuse it
  select tm.tenant_id
    into v_tenant_id
  from public.tenant_memberships tm
  where tm.user_id = v_user_id
  order by tm.created_at asc
  limit 1;

  if v_tenant_id is null then
    insert into public.tenants (name, subscription_status, subscription_tier)
    values (coalesce(nullif(p_workspace_name,''), 'Workspace'), 'trialing', 'core')
    returning id into v_tenant_id;

    insert into public.tenant_memberships (tenant_id, user_id, role)
    values (v_tenant_id, v_user_id, 'owner');
  end if;

  -- Seed first deal (safe defaults)
  insert into public.deals (
    tenant_id,
    status
  )
  values (
    v_tenant_id,
    'lead'
  )
  returning id into v_deal_id;

  return query select v_tenant_id, v_deal_id;
end;
$20260123131850_001_provision_upgrade_save$;

revoke all on function public.provision_upgrade_save(text, jsonb) from public;
grant execute on function public.provision_upgrade_save(text, jsonb) to authenticated;
