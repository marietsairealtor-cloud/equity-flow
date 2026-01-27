-- 20260124000007_002_deal_status_enum.sql
-- SAFE / type-agnostic: prevents enum=text operator errors on fresh resets.

-- Create enum if missing (no CREATE TYPE IF NOT EXISTS in Postgres)
do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'deal_status'
  ) then
    create type public.deal_status as enum (
      'New',
      'Contacted',
      'Under Contract',
      'Dead'
    );
  end if;
end
$m$;

-- Ensure deals.status uses enum (handles existing DEFAULT + common legacy values)
do $m$
begin
  -- if column missing, no-op
  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name='deals' and column_name='status'
  ) then
    return;
  end if;

  -- drop default if any (ignore errors)
  begin
    execute 'alter table public.deals alter column status drop default';
  exception when others then
    null;
  end;

  -- convert type using text mapping (works for text or enum input)
  execute
    'alter table public.deals ' ||
    'alter column status type public.deal_status ' ||
    'using ( ' ||
      'case ' ||
        'when status is null then ''New'' ' ||
        'when lower(status::text) = ''new'' then ''New'' ' ||
        'when lower(status::text) = ''contacted'' then ''Contacted'' ' ||
        'when lower(status::text) in (''under contract'',''under_contract'',''undercontract'') then ''Under Contract'' ' ||
        'when lower(status::text) = ''dead'' then ''Dead'' ' ||
        'else ''New'' end ' ||
    ')::public.deal_status';

  execute 'alter table public.deals alter column status set default ''New''::public.deal_status';
end
$m$;