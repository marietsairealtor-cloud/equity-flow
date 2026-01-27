do $20260124201457_deal_status_add_qualified_closed$
begin
  if exists (select 1 from pg_type where typname = 'deal_status') then

    if not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      where t.typname = 'deal_status' and e.enumlabel = 'Qualified'
    ) then
      execute 'alter type public.deal_status add value ''Qualified''';
    end if;

    if not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      where t.typname = 'deal_status' and e.enumlabel = 'Closed'
    ) then
      execute 'alter type public.deal_status add value ''Closed''';
    end if;

  end if;
end $20260124201457_deal_status_add_qualified_closed$;
