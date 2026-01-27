-- Pending invites + one-click accept (clean)
-- No BEGIN/COMMIT wrappers.

alter table public.tenant_invites
  add column if not exists accepted_at timestamptz,
  add column if not exists accepted_by uuid;

-- MUST drop first if signature/return type changed
drop function if exists public.get_my_pending_invites_rpc();
drop function if exists public.accept_invite_by_id_rpc(uuid);

create function public.get_my_pending_invites_rpc()
returns table (
  invite_id uuid,
  tenant_id uuid,
  workspace_name text,
  invited_role text,
  invited_email text,
  inviter_email text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, auth
as $fn$
  select
    i.id as invite_id,
    i.tenant_id,
    t.workspace_name,
    i.invited_role,
    i.invited_email,
    u.email as inviter_email,
    i.created_at
  from public.tenant_invites i
  join public.tenants t on t.id = i.tenant_id
  left join auth.users u on u.id = i.created_by
  where
    i.revoked_at is null
    and i.accepted_at is null
    and i.invited_email_lc = lower(coalesce(auth.jwt()->>'email',''));
$fn$;

grant execute on function public.get_my_pending_invites_rpc() to authenticated;

create function public.accept_invite_by_id_rpc(invite_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $plpgsql$
declare
  v_token text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select i.token
    into v_token
  from public.tenant_invites i
  where i.id = invite_id
    and i.revoked_at is null
    and i.accepted_at is null
    and i.invited_email_lc = lower(coalesce(auth.jwt()->>'email',''));

  if v_token is null then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  return public.accept_invite(v_token);
end;
$plpgsql$;

grant execute on function public.accept_invite_by_id_rpc(uuid) to authenticated;
