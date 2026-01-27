begin;

-- Backfill invited_email_lc skipped: invited_email_lc is a GENERATED column.
-- If you need to recompute, update invited_email (source column) instead.-- List my open invites (by my auth.jwt email), includes who invited me + workspace name
drop function if exists public.get_my_pending_invites_rpc();

create function public.get_my_pending_invites_rpc()
returns table (
  invite_id uuid,
  tenant_id uuid,
  workspace_name text,
  invited_role text,
  token text,
  inviter_email text,
  created_at timestamptz,
  expires_at timestamptz
)
language sql
stable
security definer
set search_path = public, auth
as $20260125084459_invites_pending_preview$
  with me as (
    select lower(coalesce(auth.jwt()->>'email','')) as email_lc
  )
  select
    i.id as invite_id,
    i.tenant_id,
    t.workspace_name,
    i.invited_role,
    i.token,
    u.email as inviter_email,
    i.created_at,
    i.expires_at
  from public.tenant_invites i
  join public.tenants t on t.id = i.tenant_id
  left join auth.users u on u.id = i.created_by
  join me on me.email_lc <> ''
  where i.invited_email_lc = me.email_lc
    and i.revoked_at is null
    and i.accepted_at is null
    and (i.expires_at is null or i.expires_at > now())
  order by i.created_at desc;
$20260125084459_invites_pending_preview$;

revoke all on function public.get_my_pending_invites_rpc() from public;
grant execute on function public.get_my_pending_invites_rpc() to authenticated;
comment on function public.get_my_pending_invites_rpc() is 'List open invites for current user email (includes inviter + workspace).';

-- Preview a token (for /app/accept-invite?token=...), shows inviter + workspace, enforces email match if JWT has email
drop function if exists public.get_invite_preview_rpc(text);

create function public.get_invite_preview_rpc(token text)
returns table (
  tenant_id uuid,
  workspace_name text,
  invited_email text,
  invited_role text,
  inviter_email text,
  created_at timestamptz,
  expires_at timestamptz,
  status text
)
language plpgsql
stable
security definer
set search_path = public, auth
as $20260125084459_invites_pending_preview$
declare
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  return query
  select
    i.tenant_id,
    t.workspace_name,
    i.invited_email,
    i.invited_role,
    u.email as inviter_email,
    i.created_at,
    i.expires_at,
    case
      when i.id is null then 'not_found'
      when i.revoked_at is not null then 'revoked'
      when i.accepted_at is not null then 'accepted'
      when i.expires_at is not null and i.expires_at <= now() then 'expired'
      when v_email <> '' and i.invited_email_lc is not null and v_email <> i.invited_email_lc then 'email_mismatch'
      else 'open'
    end as status
  from public.tenant_invites i
  join public.tenants t on t.id = i.tenant_id
  left join auth.users u on u.id = i.created_by
  where i.token = get_invite_preview_rpc.token
  limit 1;
end;
$20260125084459_invites_pending_preview$;

revoke all on function public.get_invite_preview_rpc(text) from public;
grant execute on function public.get_invite_preview_rpc(text) to authenticated;
comment on function public.get_invite_preview_rpc(text) is 'Preview invite token (shows inviter/workspace; email mismatch flagged).';

commit;
