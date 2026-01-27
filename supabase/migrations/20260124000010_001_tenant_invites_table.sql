-- tenant_invites table (must exist before any GRANT/funcs referencing it)

create table if not exists public.tenant_invites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,

  invited_email text not null,
  invited_email_lc text generated always as (lower(invited_email)) stored,

  token text not null,
  created_by uuid not null,
  created_at timestamptz not null default now(),

  revoked_at timestamptz,
  revoked_by uuid,

  accepted_at timestamptz,
  accepted_by uuid
);

create unique index if not exists tenant_invites_tenant_token_uq
  on public.tenant_invites(tenant_id, token);

create index if not exists tenant_invites_tenant_pending_idx
  on public.tenant_invites(tenant_id)
  where revoked_at is null and accepted_at is null;

alter table public.tenant_invites enable row level security;

-- Minimal RLS: members can see invites for their tenant; only members can create/revoke
drop policy if exists tenant_invites_select on public.tenant_invites;
create policy tenant_invites_select
on public.tenant_invites
for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = tenant_invites.tenant_id
      and tm.user_id = auth.uid()
  )
);

drop policy if exists tenant_invites_insert on public.tenant_invites;
create policy tenant_invites_insert
on public.tenant_invites
for insert
to authenticated
with check (
  exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = tenant_invites.tenant_id
      and tm.user_id = auth.uid()
  )
);

drop policy if exists tenant_invites_update on public.tenant_invites;
create policy tenant_invites_update
on public.tenant_invites
for update
to authenticated
using (
  exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = tenant_invites.tenant_id
      and tm.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = tenant_invites.tenant_id
      and tm.user_id = auth.uid()
  )
);

-- Grants (now safe)
grant select, insert, update, delete on table public.tenant_invites to authenticated;