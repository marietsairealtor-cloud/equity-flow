-- deal_status enum (base). Later migrations add Qualified/Closed, so do NOT include them here.

do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'deal_status'
  ) then
    create type public.deal_status as enum ('New','Contacted','Under Contract','Dead');
  end if;
end
$m$;

-- Ensure deals.status uses enum (handles existing DEFAULT + common legacy values)
do $m$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='deals'
      and column_name='status'
  ) then
    if exists (
      select 1
      from information_schema.columns
      where table_schema='public'
        and table_name='deals'
        and column_name='status'
        and udt_name <> 'deal_status'
    ) then
      begin
        execute 'alter table public.deals alter column status drop default';
      exception when others then
        null;
      end;

      execute
        'alter table public.deals ' ||
        'alter column status type public.deal_status ' ||
        'using (case lower(status::text) ' ||
          'when ''new'' then ''New''::public.deal_status ' ||
          'when ''contacted'' then ''Contacted''::public.deal_status ' ||
          'when ''under contract'' then ''Under Contract''::public.deal_status ' ||
          'when ''dead'' then ''Dead''::public.deal_status ' ||
          'else ''New''::public.deal_status end)';

      execute 'alter table public.deals alter column status set default ''New''::public.deal_status';
    end if;
  end if;
end
$m$;