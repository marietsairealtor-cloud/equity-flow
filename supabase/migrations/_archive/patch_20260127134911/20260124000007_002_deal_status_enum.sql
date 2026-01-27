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
declare
  v_col_type regtype;
begin
  select a.atttypid::regtype
    into v_col_type
  from pg_attribute a
  join pg_class c on c.oid = a.attrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'deals'
    and a.attname = 'status'
    and a.attnum > 0
    and not a.attisdropped;

  -- Fresh reset: column absent or already correct => no-op
  if v_col_type is null or v_col_type = 'public.deal_status'::regtype then
    return;
  end if;

  begin
    execute 'alter table public.deals alter column status drop default';
  exception when others then
    null;
  end;

  execute
    'alter table public.deals ' ||
    'alter column status type public.deal_status ' ||
    'using (case ' ||
      'when status is null then ''New''::public.deal_status ' ||
      'when lower(status::text) = ''new'' then ''New''::public.deal_status ' ||
      'when lower(status::text) = ''contacted'' then ''Contacted''::public.deal_status ' ||
      'when lower(status::text) in (''under contract'',''under_contract'',''undercontract'') then ''Under Contract''::public.deal_status ' ||
      'when lower(status::text) = ''dead'' then ''Dead''::public.deal_status ' ||
      'else ''New''::public.deal_status end)';

  execute 'alter table public.deals alter column status set default ''New''::public.deal_status';
end
$m$;