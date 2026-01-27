begin;

-- Create invite (owner/admin only) -> matches tenant_invites columns
create or replace function public.create_invite_rpc(tenant_id uuid, email text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_token text;
  v_seat_limit int;
  v_seat_count int;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if tenant_id is null or coalesce(email,'') = '' then
    raise exception 'tenant_id and email required';
  end if;

  if not exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = create_invite_rpc.tenant_id
      and tm.user_id = auth.uid()
      and tm.role::text in ('owner','admin')
  ) then
    raise exception 'OWNER_OR_ADMIN_ONLY';
  end if;

  select t.seat_limit, t.seat_count
    into v_seat_limit, v_seat_count
  from public.tenants t
  where t.id = create_invite_rpc.tenant_id;

  if v_seat_limit is not null and v_seat_count is not null and v_seat_count >= v_seat_limit then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  v_token := encode(extensions.gen_random_bytes(16), 'hex');

  insert into public.tenant_invites(
    tenant_id,
    invited_email,
    invited_email_lc,
    invited_role,
    token,
    created_by,
    expires_at,
    revoked_at,
    accepted_at,
    accepted_by
  )
  values (
    create_invite_rpc.tenant_id,
    email,
    lower(email),
    'member',
    v_token,
    auth.uid(),
    now() + interval '7 days',
    null,
    null,
    null
  );

  return jsonb_build_object(
    'ok', true,
    'tenant_id', create_invite_rpc.tenant_id,
    'email', lower(create_invite_rpc.email),
    'token', v_token
  );
end;
$$;

revoke all on function public.create_invite_rpc(uuid, text) from public;
grant execute on function public.create_invite_rpc(uuid, text) to authenticated;
comment on function public.create_invite_rpc(uuid, text) is 'Create invite (owner/admin).';

-- List invites for CURRENT tenant (owner/admin only)
drop function if exists public.get_invites_rpc();

create function public.get_invites_rpc()
returns table (
  id uuid,
  tenant_id uuid,
  invited_email text,
  invited_role text,
  token text,
  created_at timestamptz,
  expires_at timestamptz,
  revoked_at timestamptz,
  accepted_at timestamptz,
  accepted_by uuid
)
language sql
stable
security definer
set search_path = public, auth
as $$
  with ct as (
    select public.current_tenant_id() as tenant_id
  )
  select
    i.id,
    i.tenant_id,
    i.invited_email,
    i.invited_role,
    i.token,
    i.created_at,
    i.expires_at,
    i.revoked_at,
    i.accepted_at,
    i.accepted_by
  from public.tenant_invites i
  join ct on ct.tenant_id = i.tenant_id
  where auth.uid() is not null
    and exists (
      select 1
      from public.tenant_memberships tm
      where tm.tenant_id = i.tenant_id
        and tm.user_id = auth.uid()
        and tm.role::text in ('owner','admin')
    )
  order by i.created_at desc;
$$;

revoke all on function public.get_invites_rpc() from public;
grant execute on function public.get_invites_rpc() to authenticated;
comment on function public.get_invites_rpc() is 'List invites for CURRENT tenant (owner/admin).';

-- Revoke invite by invite id (owner/admin only)
drop function if exists public.revoke_invite_rpc(uuid);

create function public.revoke_invite_rpc(invite_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_tenant_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select i.tenant_id into v_tenant_id
  from public.tenant_invites i
  where i.id = revoke_invite_rpc.invite_id;

  if v_tenant_id is null then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  if not exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = v_tenant_id
      and tm.user_id = auth.uid()
      and tm.role::text in ('owner','admin')
  ) then
    raise exception 'OWNER_OR_ADMIN_ONLY';
  end if;

  update public.tenant_invites
  set revoked_at = now()
  where id = revoke_invite_rpc.invite_id
    and revoked_at is null
    and accepted_at is null;

  return jsonb_build_object('ok', true, 'invite_id', revoke_invite_rpc.invite_id);
end;
$$;

revoke all on function public.revoke_invite_rpc(uuid) from public;
grant execute on function public.revoke_invite_rpc(uuid) to authenticated;
comment on function public.revoke_invite_rpc(uuid) is 'Revoke invite (owner/admin).';

-- Accept invite by token (authenticated)
drop function if exists public.accept_invite_rpc(text);

create function public.accept_invite_rpc(token text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_inv public.tenant_invites%rowtype;
  v_email text;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_email := lower(coalesce(auth.jwt()->>'email',''));

  select *
  into v_inv
  from public.tenant_invites i
  where i.token = accept_invite_rpc.token
  limit 1;

  if v_inv.id is null then
    raise exception 'INVITE_NOT_FOUND';
  end if;

  if v_inv.revoked_at is not null then
    raise exception 'INVITE_REVOKED';
  end if;

  if v_inv.accepted_at is not null then
    raise exception 'INVITE_ALREADY_ACCEPTED';
  end if;

  if v_inv.expires_at is not null and v_inv.expires_at < now() then
    raise exception 'INVITE_EXPIRED';
  end if;

  -- If we have email in JWT, enforce match to invited_email_lc
  if v_email <> '' and v_inv.invited_email_lc is not null and v_email <> v_inv.invited_email_lc then
    raise exception 'EMAIL_MISMATCH';
  end if;

  -- Ensure membership (role from invite)
  insert into public.tenant_memberships(tenant_id, user_id, role)
  values (v_inv.tenant_id, auth.uid(), v_inv.invited_role::public.tenant_role)
  on conflict (tenant_id, user_id) do nothing;

  update public.tenant_invites
  set accepted_at = now(),
      accepted_by = auth.uid()
  where id = v_inv.id;

  -- Set current tenant if profile exists
  if to_regclass('public.user_profiles') is not null then
    update public.user_profiles
    set current_tenant_id = v_inv.tenant_id
    where user_id = auth.uid();
  end if;

  return jsonb_build_object('ok', true, 'tenant_id', v_inv.tenant_id, 'role', v_inv.invited_role);
end;
$$;

revoke all on function public.accept_invite_rpc(text) from public;
grant execute on function public.accept_invite_rpc(text) to authenticated;
comment on function public.accept_invite_rpc(text) is 'Accept invite by token; creates membership and selects tenant.';

commit;
