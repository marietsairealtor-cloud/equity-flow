create or replace function public.get_current_tenant_id()
returns uuid
language sql
security definer
set search_path = public, extensions, pg_temp
as $function$
  select up.current_tenant_id
  from public.user_profiles up
  where up.user_id = auth.uid();
$function$;

revoke all on function public.get_current_tenant_id() from public;
grant execute on function public.get_current_tenant_id() to authenticated;