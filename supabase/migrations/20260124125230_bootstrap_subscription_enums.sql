-- Idempotent enum bootstrap
do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'subscription_status'
  ) then
    create type public.subscription_status as enum ('pending','trialing','active','past_due','canceled','locked');
  end if;
end
$m$;
do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'subscription_tier'
  ) then
    create type public.subscription_tier as enum ('free','core');
  end if;
end
$m$;