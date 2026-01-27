-- No-token invite discovery + accept RPCs
-- Canonical names; no overloads; no signature churn.

drop function if exists public.get_my_pending_invites_rpc();
drop function if exists public.accept_my_invite_rpc(uuid);

create function public.get_my_pending_invites_rpc()
returns table (
  invite_id uuid,
  tenant_id uuid,
  workspace_name text,
  invited_role text,
  inviter_email text,
  created_at timestamptz
)
language sql
security definer
stable
set search_path = public, auth, extensions
as $$
  with me as (
    select lower(u.email) as email_lc
    from auth.users u
    where u.id = auth.uid()
  )
  select
    i.id as invite_id,
    i.tenant_id,
    t.workspace_name,
    i.invited_role,
    (select u.email from auth.users u where u.id = i.created_by) as inviter_email,
    i.created_at
  from public.tenant_invites i
  join public.tenants t on t.id = i.tenant_id
  join me on true
  where
    i.revoked_at is null
    and i.accepted_at is null
    and i.invited_email_lc = me.email_lc
  order by i.created_at desc;
$$;

revoke all on function public.get_my_pending_invites_rpc() from public;
grant execute on function public.get_my_pending_invites_rpc() to authenticated;

create function public.accept_my_invite_rpc(p_invite_id uuid)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public, auth, extensions
as $$
declare
  v_token text;
  v_my_email_lc text;
begin
  select lower(u.email) into v_my_email_lc
  from auth.users u
  where u.id = auth.uid();

  if v_my_email_lc is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select i.token into v_token
  from public.tenant_invites i
  where
    i.id = p_invite_id
    and i.revoked_at is null
    and i.accepted_at is null
    and i.invited_email_lc = v_my_email_lc;

  if v_token is null then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  return public.accept_invite(v_token);
end;
$$;

revoke all on function public.accept_my_invite_rpc(uuid) from public;
grant execute on function public.accept_my_invite_rpc(uuid) to authenticated;
