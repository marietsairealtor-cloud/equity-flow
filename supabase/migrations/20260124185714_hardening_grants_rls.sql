-- Ensure RLS is enabled (idempotent)
alter table if exists public.tenants enable row level security;
alter table if exists public.tenant_memberships enable row level security;
alter table if exists public.deals enable row level security;
alter table if exists public.tenant_invites enable row level security;
alter table if exists public.user_profiles enable row level security;

-- Table privileges for app runtime (RLS still gates rows)
grant usage on schema public to authenticated;

grant select, insert, update, delete on table public.tenants to authenticated;
grant select, insert, update, delete on table public.tenant_memberships to authenticated;
grant select, insert, update, delete on table public.deals to authenticated;
grant select, insert, update, delete on table public.tenant_invites to authenticated;
grant select, insert, update, delete on table public.user_profiles to authenticated;

-- Keep anon minimal
revoke all on table public.tenants from anon;
revoke all on table public.tenant_memberships from anon;
revoke all on table public.deals from anon;
revoke all on table public.tenant_invites from anon;
revoke all on table public.user_profiles from anon;