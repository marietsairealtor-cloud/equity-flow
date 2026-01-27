begin;
create extension if not exists pgcrypto;

-- Enums (idempotent)
do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'subscription_status'
  ) then
    create type public.subscription_status as enum ('pending','trialing','active','past_due','canceled','locked');
  end if;
end
$m$;
do $m$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'subscription_tier'
  ) then
    create type public.subscription_tier as enum ('free','core');
  end if;
end
$m$;

-- Tenants
create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  workspace_name text not null,
  workspace_name_lc text generated always as (lower(workspace_name)) stored,
  subscription_tier public.subscription_tier not null default 'free',
  subscription_status public.subscription_status not null default 'pending',
  trial_started_at timestamptz,
  trial_ends_at timestamptz,
  seats_limit int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists tenants_workspace_name_lc_ux
  on public.tenants (workspace_name_lc)
  where deleted_at is null;

-- Memberships
create table if not exists public.tenant_memberships (
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null,
  role text not null check (role in ('owner','member')),
  created_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

-- User profiles (for current_tenant_id)
create table if not exists public.user_profiles (
  user_id uuid primary key,
  current_tenant_id uuid references public.tenants(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Deals (minimal)
create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  status text not null default 'New',
  row_version int not null default 1,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
do $m$
begin
  if not exists (select 1 from pg_constraint where conname = 'deals_status_check') then
    alter table public.deals
      add constraint deals_status_check
      check (status in ('New','Contacted','Qualified','Under Contract','Closed','Dead'));
  end if;
end
$m$;

-- Audit log (minimal)
create table if not exists public.audit_log (
  id bigserial primary key,
  tenant_id uuid,
  actor_user_id uuid,
  action text not null,
  entity_type text,
  entity_id uuid,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Invites (minimal, to avoid downstream missing-table failures)
create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  invited_email text not null,
  invited_email_lc text,
  token text,
  token_hash text,
  revoked_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid
);

commit;