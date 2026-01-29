begin;

alter table public.tenants
  add column if not exists name text;

-- backfill from workspace_name if present
update public.tenants
set name = coalesce(name, workspace_name)
where name is null;

create or replace function public.tenants_sync_name()
returns trigger
language plpgsql
as $fn$
begin
  -- keep both columns populated when either exists
  if new.name is null and new.workspace_name is not null then
    new.name := new.workspace_name;
  end if;

  if new.workspace_name is null and new.name is not null then
    new.workspace_name := new.name;
  end if;

  return new;
end;
$fn$;

drop trigger if exists trg_tenants_sync_name on public.tenants;

create trigger trg_tenants_sync_name
before insert or update on public.tenants
for each row
execute function public.tenants_sync_name();

commit;