-- Fix: accept_my_invite_rpc must return valid JSONB for Supabase/PostgREST.
-- Keep signature stable (uuid -> jsonb). Only change body.

create or replace function public.accept_my_invite_rpc(p_invite_id uuid)
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

  -- IMPORTANT: do not return accept_invite(...) directly (may not be JSON).
  perform public.accept_invite(v_token);

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.accept_my_invite_rpc(uuid) from public;
grant execute on function public.accept_my_invite_rpc(uuid) to authenticated;