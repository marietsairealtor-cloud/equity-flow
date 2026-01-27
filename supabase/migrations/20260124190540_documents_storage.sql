-- Bucket
insert into storage.buckets (id, name, public)
values ('deal-files', 'deal-files', false)
on conflict (id) do nothing;

-- Helper: parse tenant_id + deal_id from storage path "tenant_id/deal_id/..."
create or replace function public.storage_tenant_id(p_name text)
returns uuid
language sql
stable
as $function$
  select nullif(split_part(p_name,'/',1),'')::uuid;
$function$;

create or replace function public.storage_deal_id(p_name text)
returns uuid
language sql
stable
as $function$
  select nullif(split_part(p_name,'/',2),'')::uuid;
$function$;

-- Documents table
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  deal_id uuid not null references public.deals(id) on delete cascade,
  storage_bucket text not null default 'deal-files',
  storage_path text not null,
  file_name text,
  mime_type text,
  size_bytes bigint,
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid()
);

create index if not exists documents_tenant_id_idx on public.documents(tenant_id);
create index if not exists documents_deal_id_idx on public.documents(deal_id);

alter table public.documents enable row level security;

-- RLS: tenant scoped
drop policy if exists documents_select on public.documents;
create policy documents_select
on public.documents
for select
to authenticated
using (tenant_id = public.current_tenant_id());

drop policy if exists documents_insert on public.documents;
create policy documents_insert
on public.documents
for insert
to authenticated
with check (tenant_id = public.current_tenant_id() and public.can_write_current_tenant());

drop policy if exists documents_update on public.documents;
create policy documents_update
on public.documents
for update
to authenticated
using (tenant_id = public.current_tenant_id())
with check (tenant_id = public.current_tenant_id() and public.can_write_current_tenant());

drop policy if exists documents_delete on public.documents;
create policy documents_delete
on public.documents
for delete
to authenticated
using (tenant_id = public.current_tenant_id() and public.can_write_current_tenant());

-- Grants
grant select, insert, update, delete on table public.documents to authenticated;

-- RPC: create doc row after upload
create or replace function public.create_document_after_upload(
  p_deal_id uuid,
  p_storage_path text,
  p_file_name text,
  p_mime_type text,
  p_size_bytes bigint
)
returns uuid
language plpgsql
security definer
as $function$
declare
  v_tenant uuid;
  v_id uuid;
begin
  v_tenant := public.current_tenant_id();
  if v_tenant is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if public.storage_tenant_id(p_storage_path) is distinct from v_tenant
     or public.storage_deal_id(p_storage_path) is distinct from p_deal_id then
    raise exception 'PATH_MISMATCH';
  end if;

  insert into public.documents (
    tenant_id, deal_id, storage_bucket, storage_path, file_name, mime_type, size_bytes
  ) values (
    v_tenant, p_deal_id, 'deal-files', p_storage_path, p_file_name, p_mime_type, p_size_bytes
  )
  returning id into v_id;

  return v_id;
end $function$;

revoke all on function public.create_document_after_upload(uuid, text, text, text, bigint) from public;
grant execute on function public.create_document_after_upload(uuid, text, text, text, bigint) to authenticated;

-- Storage RLS policies MUST be created in Supabase Dashboard Storage Policies UI
-- because role ownership for storage.objects is not available via CLI migrations.