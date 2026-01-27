-- Core context helpers (must exist before entitlements/functions that reference them)

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
set search_path = public, auth
as $function$
  select coalesce(
    nullif(auth.jwt()->>'tenant_id','')::uuid,
    nullif(current_setting('app.tenant_id', true),'')::uuid
  );
$function$;

grant execute on function public.current_tenant_id() to anon, authenticated;