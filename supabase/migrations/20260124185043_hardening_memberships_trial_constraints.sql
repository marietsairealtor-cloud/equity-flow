create unique index if not exists tenant_memberships_tenant_user_ux
on public.tenant_memberships(tenant_id, user_id);

do $function$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'tenants_trial_fields_chk'
      and conrelid = 'public.tenants'::regclass
  ) then
    alter table public.tenants
      add constraint tenants_trial_fields_chk
      check (
        subscription_status <> 'trialing'::public.subscription_status
        or (
          trial_started_at is not null
          and trial_ends_at is not null
          and trial_ends_at > trial_started_at
        )
      );
  end if;
end $function$;