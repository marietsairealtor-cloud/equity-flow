-- Deal status RPC (stable signature)
create or replace function public.update_deal_status_rpc(
  p_deal_id uuid,
  p_status text,
  p_expected_row_version integer
)
returns table (
  id uuid,
  row_version integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_row_version integer;
begin
  -- hard gate: must have write access for current tenant
  if not public.can_write_current_tenant() then
    raise exception 'WRITE_NOT_ALLOWED' using errcode = '42501';
  end if;

  update public.deals d
     set status = p_status,
         row_version = d.row_version + 1,
         updated_at = now()
   where d.id = p_deal_id
     and d.tenant_id = public.current_tenant_id()
     and d.row_version = p_expected_row_version
  returning d.id, d.row_version into v_id, v_row_version;

  if v_id is null then
    raise exception 'CONFLICT_OR_NOT_FOUND' using errcode = '40900';
  end if;

  id := v_id;
  row_version := v_row_version;
  return next;
end
$$;

revoke all on function public.update_deal_status_rpc(uuid, text, integer) from public;
grant execute on function public.update_deal_status_rpc(uuid, text, integer) to authenticated;
