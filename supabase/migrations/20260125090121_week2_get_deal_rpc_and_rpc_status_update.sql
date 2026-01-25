-- Week 2: get_deal RPC (clean rewrite). No BEGIN/COMMIT wrappers.

drop function if exists public.get_deal(uuid);

create function public.get_deal(deal_id uuid)
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
  where d.id = deal_id
    and d.tenant_id = public.current_tenant_id();
$fn$;

grant execute on function public.get_deal(uuid) to authenticated;