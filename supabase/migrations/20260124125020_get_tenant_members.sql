-- get_tenant_members: returns membership + email for the given tenant

create or replace function public.get_tenant_members(p_tenant_id uuid)
returns table(user_id uuid, email text, role text, created_at timestamptz)
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    tm.user_id,
    u.email,
    (tm.role)::text as role,
    tm.created_at
  from public.tenant_memberships tm
  join auth.users u on u.id = tm.user_id
  where tm.tenant_id = p_tenant_id
    and public.is_member(p_tenant_id)
  order by tm.created_at asc;
$$;

grant execute on function public.get_tenant_members(uuid) to authenticated;
