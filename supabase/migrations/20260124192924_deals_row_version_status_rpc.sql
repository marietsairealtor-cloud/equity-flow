-- row_version for optimistic concurrency
alter table public.deals
  add column if not exists row_version int not null default 1;

-- RPC: set status with optional optimistic concurrency check
create or replace function public.set_deal_status(
  p_deal_id uuid,
  p_status public.deal_status,
  p_expected_row_version int default null
)
returns table(id uuid, status public.deal_status, row_version int)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
begin
  if public.current_tenant_id() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not public.can_write_current_tenant() then
    raise exception 'WRITE_NOT_ALLOWED';
  end if;

  return query
  update public.deals d
  set
    status = p_status,
    row_version = d.row_version + 1
  where
    d.id = p_deal_id
    and d.tenant_id = public.current_tenant_id()
    and (p_expected_row_version is null or d.row_version = p_expected_row_version)
  returning d.id, d.status, d.row_version;

  if not found then
    if p_expected_row_version is null then
      raise exception 'NOT_FOUND';
    else
      raise exception 'ROW_VERSION_CONFLICT';
    end if;
  end if;
end $$;

revoke all on function public.set_deal_status(uuid, public.deal_status, int) from public;
grant execute on function public.set_deal_status(uuid, public.deal_status, int) to authenticated;