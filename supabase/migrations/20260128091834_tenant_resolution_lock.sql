-- tenant-resolution lock (profile > app.tenant_id override > jwt claim > null)

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
as '
  select coalesce(
    (select up.current_tenant_id
       from public.user_profiles up
      where up.user_id = auth.uid()
    ),
    (case
       when current_setting(''app.tenant_id'', true) ~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$''
       then current_setting(''app.tenant_id'', true)::uuid
     end),
    (case
       when (coalesce(current_setting(''app.jwt_tenant_enabled'', true), '''') = ''true'')
        and (auth.jwt()->>''tenant_id'') ~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$''
       then (auth.jwt()->>''tenant_id'')::uuid
     end)
  );
';

create or replace function public.current_tenant_mismatch()
returns boolean
language sql
stable
as '
  select
    (select up.current_tenant_id
       from public.user_profiles up
      where up.user_id = auth.uid()
    ) is not null
    and (coalesce(current_setting(''app.jwt_tenant_enabled'', true), '''') = ''true'')
    and (auth.jwt()->>''tenant_id'') ~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$''
    and (select up.current_tenant_id
           from public.user_profiles up
          where up.user_id = auth.uid()
        ) <> (auth.jwt()->>''tenant_id'')::uuid;
';