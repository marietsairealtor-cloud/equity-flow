-- 1) Default seat limit = 100, and upgrade existing default-ish rows
alter table public.tenants
  alter column seat_limit set default 100;

update public.tenants
set seat_limit = 100
where seat_limit = 1;

-- 2) Fix create_invite_rpc: do NOT insert invited_email_lc (generated/identity)
-- Must keep original param names to avoid 42P13.
drop function if exists public.create_invite_rpc(uuid, text);

create function public.create_invite_rpc(tenant_id uuid, email text)
returns jsonb
language plpgsql
security definer
volatile
set search_path = public, auth, extensions
as $20260125203123_seat_limit_100_and_invite_lc_fix$
declare
  v_token text;
  v_email text;
  v_email_lc text;
  v_invite_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_email := trim(email);
  v_email_lc := lower(v_email);

  if v_email_lc is null or v_email_lc = '' then
    raise exception 'EMAIL_REQUIRED';
  end if;

  v_token := encode(extensions.gen_random_bytes(24), 'hex');

  insert into public.tenant_invites (
    tenant_id,
    invited_email,
    invited_role,
    token,
    created_by
  )
  values (
    tenant_id,
    v_email,
    'member',
    v_token,
    auth.uid()
  )
  returning id into v_invite_id;

  return jsonb_build_object(
    'ok', true,
    'invite_id', v_invite_id,
    'email', v_email,
    'token', v_token,
    'tenant_id', tenant_id
  );
end;
$20260125203123_seat_limit_100_and_invite_lc_fix$;

revoke all on function public.create_invite_rpc(uuid, text) from public;
grant execute on function public.create_invite_rpc(uuid, text) to authenticated;
