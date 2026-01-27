-- Week 3: Upgrade & Save idempotency (deal-level)
begin;
-- 1) Add idempotency key to deals
alter table public.deals
  add column if not exists idempotency_key text;

-- Unique per tenant to allow retry-safe create
create unique index if not exists deals_tenant_id_idempotency_key_ux
  on public.deals(tenant_id, idempotency_key)
  where idempotency_key is not null;

-- 2) Replace provision_upgrade_save to accept an idempotency key and reuse the seeded deal on retries.
-- Signature change is intentional and canonical.
drop function if exists public.provision_upgrade_save(text, jsonb);

create or replace function public.provision_upgrade_save(
  p_workspace_name text,
  p_first_deal jsonb,
  p_idempotency_key text default null
)
returns table (tenant_id uuid, deal_id uuid)
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_existing_deal_id uuid;
  v_deal_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  -- Reuse first tenant membership for the user if it exists
  select tm.tenant_id
    into v_tenant_id
  from public.tenant_memberships tm
  where tm.user_id = v_user_id
  order by tm.created_at asc
  limit 1;

  -- Create tenant + owner membership if missing
  if v_tenant_id is null then
    insert into public.tenants (workspace_name, subscription_status, trial_started_at, trial_ends_at)
    values (coalesce(p_workspace_name,''), 'trialing'::public.subscription_status, now(), now() + interval '14 days')
    returning id into v_tenant_id;

    insert into public.tenant_memberships (tenant_id, user_id, role)
    values (v_tenant_id, v_user_id, 'owner');
  end if;

  -- If idempotency_key provided and a deal already exists for this tenant, reuse it
  if p_idempotency_key is not null then
    select d.id into v_existing_deal_id
    from public.deals d
    where d.tenant_id = v_tenant_id
      and d.idempotency_key = p_idempotency_key
    limit 1;

    if v_existing_deal_id is not null then
      tenant_id := v_tenant_id;
      deal_id := v_existing_deal_id;
      return next;
      return;
    end if;
  end if;

  -- Seed first deal
  insert into public.deals (tenant_id, status, market_area, idempotency_key)
  values (
    v_tenant_id,
    coalesce((p_first_deal->>'status')::public.deal_status, 'New'::public.deal_status),
    coalesce(p_first_deal->>'market_area', 'default'),
    p_idempotency_key
  )
  returning id into v_deal_id;

  tenant_id := v_tenant_id;
  deal_id := v_deal_id;
  return next;
end;
$function$;

grant execute on function public.provision_upgrade_save(text, jsonb, text) to authenticated;

commit;