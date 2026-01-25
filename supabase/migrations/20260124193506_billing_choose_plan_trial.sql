-- subscription_tier enum (idempotent)
do $$
begin
  if not exists (select 1 from pg_type where typname = 'subscription_tier') then
    create type public.subscription_tier as enum ('free','core');
  end if;
end $$;

-- tenants.subscription_tier (idempotent)
do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name='tenants' and column_name='subscription_tier'
  ) then
    alter table public.tenants
      add column subscription_tier public.subscription_tier not null default 'free'::public.subscription_tier;
  end if;
end $$;

update public.tenants
set subscription_tier = coalesce(subscription_tier, 'free'::public.subscription_tier);

-- choose plan + start trial (owner/admin only)
create or replace function public.choose_plan_and_start_trial(p_tier public.subscription_tier)
returns table(
  tenant_id uuid,
  tier public.subscription_tier,
  status public.subscription_status,
  trial_ends_at timestamptz,
  seat_limit int,
  seat_count int
)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_tenant uuid;
  v_status public.subscription_status;
begin
  v_tenant := public.current_tenant_id();
  if v_tenant is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.is_owner_or_admin(v_tenant) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select subscription_status into v_status
  from public.tenants
  where id = v_tenant;

  -- Set tier always
  update public.tenants
  set subscription_tier = p_tier
  where id = v_tenant;

  -- Only auto-start trial when moving from pending -> trialing
  if v_status = 'pending'::public.subscription_status and p_tier = 'core'::public.subscription_tier then
    update public.tenants
    set
      subscription_status = 'trialing'::public.subscription_status,
      trial_started_at = now(),
      trial_ends_at = now() + interval '14 days'
    where id = v_tenant;
  end if;

  return query
  select
    t.id,
    t.subscription_tier,
    t.subscription_status,
    t.trial_ends_at,
    t.seat_limit,
    t.seat_count
  from public.tenants t
  where t.id = v_tenant;
end $$;

revoke all on function public.choose_plan_and_start_trial(public.subscription_tier) from public;
grant execute on function public.choose_plan_and_start_trial(public.subscription_tier) to authenticated;