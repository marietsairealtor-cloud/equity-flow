drop extension if exists "pg_net";

create type "public"."subscription_status" as enum ('trialing', 'active', 'past_due', 'canceled', 'locked', 'pending');

create type "public"."subscription_tier" as enum ('free', 'core');

create sequence "public"."_rpc_grants_snapshot_id_seq";


  create table "public"."_rpc_grants_snapshot" (
    "id" bigint not null default nextval('public._rpc_grants_snapshot_id_seq'::regclass),
    "created_at" timestamp with time zone not null default now(),
    "grantee" text not null,
    "fn_count" integer not null
      );


alter table "public"."_rpc_grants_snapshot" enable row level security;


  create table "public"."audit_log" (
    "id" uuid not null default gen_random_uuid(),
    "tenant_id" uuid not null,
    "user_id" uuid not null,
    "action" text not null,
    "entity_type" text not null,
    "entity_id" uuid,
    "at" timestamp with time zone not null default now(),
    "meta" jsonb not null default '{}'::jsonb
      );


alter table "public"."audit_log" enable row level security;


  create table "public"."deals" (
    "id" uuid not null default gen_random_uuid(),
    "tenant_id" uuid not null default public.current_tenant_id(),
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now(),
    "market_area" text not null,
    "property_address" text,
    "postal_code" text,
    "beds" numeric,
    "baths" numeric,
    "sqft" numeric,
    "property_type" text,
    "dwelling_type" text,
    "parking" text,
    "motivation" text,
    "seller_timeline" text,
    "notes" text,
    "tags" text[],
    "condition_notes" text,
    "repairs_required" text[],
    "repair_estimate" numeric,
    "asking_price" numeric,
    "mortgage_owing" numeric,
    "arv" numeric,
    "purchase_price" numeric,
    "assignment_fee" numeric,
    "wholesale_price" numeric,
    "status" text not null default 'new'::text,
    "lead_source" text,
    "calc_version" text not null default 'v1'::text,
    "row_version" integer not null default 1,
    "country_code" text not null default 'US'::text,
    "currency_code" text not null default 'USD'::text,
    "measurement_unit" text not null default 'imperial'::text,
    "assigned_tc_contact_id" uuid,
    "seller_contact_id" uuid
      );


alter table "public"."deals" enable row level security;


  create table "public"."tenant_memberships" (
    "tenant_id" uuid not null,
    "user_id" uuid not null,
    "role" text not null default 'member'::text,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."tenant_memberships" enable row level security;


  create table "public"."tenants" (
    "id" uuid not null default gen_random_uuid(),
    "billing_email" text,
    "country_code" text default 'CA'::text,
    "currency_code" text default 'CAD'::text,
    "measurement_unit" text default 'metric'::text,
    "subscription_tier" public.subscription_tier not null,
    "created_at" timestamp with time zone default now(),
    "trial_started_at" timestamp with time zone,
    "trial_ends_at" timestamp with time zone,
    "subscription_status" text,
    "subscription_started_at" timestamp with time zone,
    "subscription_ends_at" timestamp with time zone,
    "canceled_at" timestamp with time zone,
    "locked_at" timestamp with time zone,
    "onboarding_completed_at" timestamp with time zone,
    "workspace_name" text default ''::text,
    "is_beta" boolean not null default false
      );


alter table "public"."tenants" enable row level security;

alter sequence "public"."_rpc_grants_snapshot_id_seq" owned by "public"."_rpc_grants_snapshot"."id";

CREATE UNIQUE INDEX "0_subscribers_email_key" ON public.tenants USING btree (billing_email);

CREATE UNIQUE INDEX "0_subscribers_pkey" ON public.tenants USING btree (id);

CREATE UNIQUE INDEX _rpc_grants_snapshot_pkey ON public._rpc_grants_snapshot USING btree (id);

CREATE UNIQUE INDEX audit_log_pkey ON public.audit_log USING btree (id);

CREATE INDEX audit_log_tenant_at_idx ON public.audit_log USING btree (tenant_id, at DESC);

CREATE INDEX deals_assigned_tc_contact_id_idx ON public.deals USING btree (assigned_tc_contact_id);

CREATE UNIQUE INDEX deals_pkey ON public.deals USING btree (id);

CREATE UNIQUE INDEX tenant_memberships_pkey ON public.tenant_memberships USING btree (tenant_id, user_id);

CREATE UNIQUE INDEX tenant_memberships_unique_user_per_tenant ON public.tenant_memberships USING btree (tenant_id, user_id);

CREATE INDEX tenant_memberships_user_id_idx ON public.tenant_memberships USING btree (user_id);

alter table "public"."_rpc_grants_snapshot" add constraint "_rpc_grants_snapshot_pkey" PRIMARY KEY using index "_rpc_grants_snapshot_pkey";

alter table "public"."audit_log" add constraint "audit_log_pkey" PRIMARY KEY using index "audit_log_pkey";

alter table "public"."deals" add constraint "deals_pkey" PRIMARY KEY using index "deals_pkey";

alter table "public"."tenant_memberships" add constraint "tenant_memberships_pkey" PRIMARY KEY using index "tenant_memberships_pkey";

alter table "public"."tenants" add constraint "0_subscribers_pkey" PRIMARY KEY using index "0_subscribers_pkey";

alter table "public"."audit_log" add constraint "audit_log_tenant_id_fkey" FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE not valid;

alter table "public"."audit_log" validate constraint "audit_log_tenant_id_fkey";

alter table "public"."deals" add constraint "deals_status_check" CHECK ((status = ANY (ARRAY['New'::text, 'Contacted'::text, 'Appointment Set'::text, 'Offer Made'::text, 'Under Contract'::text, 'Closed/Assigned'::text, 'Dead'::text]))) not valid;

alter table "public"."deals" validate constraint "deals_status_check";

alter table "public"."deals" add constraint "deals_tenant_id_fkey" FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE not valid;

alter table "public"."deals" validate constraint "deals_tenant_id_fkey";

alter table "public"."tenant_memberships" add constraint "tenant_memberships_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'member'::text]))) not valid;

alter table "public"."tenant_memberships" validate constraint "tenant_memberships_role_check";

alter table "public"."tenant_memberships" add constraint "tenant_memberships_tenant_id_fkey" FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE not valid;

alter table "public"."tenant_memberships" validate constraint "tenant_memberships_tenant_id_fkey";

alter table "public"."tenant_memberships" add constraint "tenant_memberships_unique_user_per_tenant" UNIQUE using index "tenant_memberships_unique_user_per_tenant";

alter table "public"."tenant_memberships" add constraint "tenant_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."tenant_memberships" validate constraint "tenant_memberships_user_id_fkey";

alter table "public"."tenants" add constraint "0_subscribers_email_key" UNIQUE using index "0_subscribers_email_key";

alter table "public"."tenants" add constraint "tenants_country_code_check" CHECK ((country_code = ANY (ARRAY['US'::text, 'CA'::text]))) not valid;

alter table "public"."tenants" validate constraint "tenants_country_code_check";

alter table "public"."tenants" add constraint "tenants_country_code_len" CHECK ((length(country_code) = ANY (ARRAY[2, 3]))) not valid;

alter table "public"."tenants" validate constraint "tenants_country_code_len";

alter table "public"."tenants" add constraint "tenants_currency_code_check" CHECK ((currency_code = ANY (ARRAY['USD'::text, 'CAD'::text]))) not valid;

alter table "public"."tenants" validate constraint "tenants_currency_code_check";

alter table "public"."tenants" add constraint "tenants_currency_code_len" CHECK ((length(currency_code) = 3)) not valid;

alter table "public"."tenants" validate constraint "tenants_currency_code_len";

alter table "public"."tenants" add constraint "tenants_measurement_unit" CHECK ((measurement_unit = ANY (ARRAY['imperial'::text, 'metric'::text]))) not valid;

alter table "public"."tenants" validate constraint "tenants_measurement_unit";

alter table "public"."tenants" add constraint "tenants_measurement_unit_check" CHECK ((measurement_unit = ANY (ARRAY['imperial'::text, 'metric'::text]))) not valid;

alter table "public"."tenants" validate constraint "tenants_measurement_unit_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.admin_set_subscription(p_tenant_id uuid, p_tier text, p_status public.subscription_status)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  if p_tier not in ('free','core') then
    raise exception 'invalid tier';
  end if;

  update public.tenants
  set
    subscription_tier = p_tier::subscription_tier,
    subscription_status = p_status
  where id = p_tenant_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.apply_billing_event(p_event_id text, p_event_type text, p_tenant_id uuid, p_payload jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_is_new boolean;
begin
  insert into public.billing_events (provider, event_id, event_type, tenant_id, payload)
  values ('stripe', p_event_id, p_event_type, p_tenant_id, p_payload)
  on conflict (provider, event_id) do nothing;

  select exists (
    select 1
    from public.billing_events
    where provider = 'stripe'
      and event_id = p_event_id
      and processed_at is null
  ) into v_is_new;

  if not v_is_new then
    return false;
  end if;

  -- HARD LOCK (fraud/chargeback/admin)
  if p_event_type = 'chargeback.created' then
    update public.tenants
       set subscription_status = 'locked',
           locked_at = now()
     where id = p_tenant_id;
  end if;

  -- CHECKOUT → ACTIVE (+tier)
  if p_event_type = 'checkout.session.completed' then
    update public.tenants
       set subscription_status = 'active',
           subscription_tier = coalesce(
             (p_payload->>'subscription_tier')::public.subscription_tier,
             subscription_tier
           ),
           subscription_started_at = now(),
           canceled_at = null,
           locked_at = null
     where id = p_tenant_id
       and subscription_status <> 'locked';
  end if;

  -- PAYMENT FAILED → PAST DUE
  if p_event_type = 'invoice.payment_failed' then
    update public.tenants
       set subscription_status = 'past_due'
     where id = p_tenant_id
       and subscription_status <> 'locked';
  end if;

  -- PAYMENT RECOVERED → ACTIVE
  if p_event_type = 'invoice.payment_succeeded' then
    update public.tenants
       set subscription_status = 'active',
           canceled_at = null
     where id = p_tenant_id
       and subscription_status = 'past_due';
  end if;

  -- SUBSCRIPTION CANCELED → CANCELED
  if p_event_type = 'customer.subscription.deleted' then
    update public.tenants
       set subscription_status = 'canceled',
           canceled_at = now()
     where id = p_tenant_id
       and subscription_status <> 'locked';
  end if;

  update public.billing_events
     set processed_at = now(),
         processing_error = null
   where provider = 'stripe'
     and event_id = p_event_id
     and processed_at is null;

  return true;

exception when others then
  update public.billing_events
     set processing_error = sqlstate || ': ' || sqlerrm
   where provider = 'stripe'
     and event_id = p_event_id
     and processed_at is null;
  raise;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.can_write_current_tenant()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select public.tenant_write_allowed(public.current_tenant_id());
$function$
;

CREATE OR REPLACE FUNCTION public.create_deal(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid := gen_random_uuid();
begin
  insert into public.deals (
    id, tenant_id, created_at, updated_at,
    market_area, property_address, postal_code,
    beds, baths, sqft,
    property_type, dwelling_type, parking,
    motivation, seller_timeline, notes,
    tags, repairs_required,
    repair_estimate, asking_price, mortgage_owing, arv,
    purchase_price, assignment_fee, wholesale_price,
    status, lead_source,
    calc_version, row_version,
    country_code, currency_code, measurement_unit,
    assigned_tc_contact_id, seller_contact_id
  )
  values (
    v_id, v_tenant_id, now(), now(),
    p->>'market_area',
    p->>'property_address',
    p->>'postal_code',
    nullif(p->>'beds','')::numeric,
    nullif(p->>'baths','')::numeric,
    nullif(p->>'sqft','')::numeric,
    p->>'property_type',
    p->>'dwelling_type',
    p->>'parking',
    p->>'motivation',
    p->>'seller_timeline',
    p->>'notes',
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(p->'tags','[]'::jsonb)) x), '{}'::text[]),
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(p->'repairs_required','[]'::jsonb)) x), '{}'::text[]),
    nullif(p->>'repair_estimate','')::numeric,
    nullif(p->>'asking_price','')::numeric,
    nullif(p->>'mortgage_owing','')::numeric,
    nullif(p->>'arv','')::numeric,
    nullif(p->>'purchase_price','')::numeric,
    nullif(p->>'assignment_fee','')::numeric,
    nullif(p->>'wholesale_price','')::numeric,
    p->>'status',
    p->>'lead_source',
    coalesce(p->>'calc_version','1'),
    1,
    p->>'country_code',
    p->>'currency_code',
    p->>'measurement_unit',
    nullif(p->>'assigned_tc_contact_id','')::uuid,
    nullif(p->>'seller_contact_id','')::uuid
  );

  insert into public.audit_log(tenant_id, user_id, action, entity_type, entity_id, meta)
  values (v_tenant_id, auth.uid(), 'create', 'deal', v_id, p);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('id', v_id));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_market_area(p_area_name text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_tenant_id uuid;
  v_new_record json;
BEGIN
  -- Resolve Tenant
  v_tenant_id := public.current_tenant_id();

  -- HARD STOP: If no tenant, fail loud.
  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'User % has no current_tenant_id. Cannot create market area.', auth.uid();
  END IF;

  -- Insert and Return the full row
  INSERT INTO public.tenant_market_areas (tenant_id, area_name)
  VALUES (v_tenant_id, p_area_name)
  RETURNING json_build_object('id', id, 'area_name', area_name) INTO v_new_record;

  RETURN v_new_record;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_workspace(p_subscription_tier text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_tenant_id uuid;
begin
  -- create tenant
  insert into public.tenants (
    subscription_tier,
    subscription_status,
    trial_started_at,
    trial_ends_at
  )
  values (
    p_subscription_tier,
    'trialing',
    now(),
    now() + interval '14 days'
  )
  returning id into v_tenant_id;

  -- create membership
  insert into public.tenant_memberships (
    tenant_id,
    user_id,
    role
  )
  values (
    v_tenant_id,
    auth.uid(),
    'owner'
  );

  -- set current tenant
  update public.user_profiles
  set current_tenant_id = v_tenant_id
  where user_id = auth.uid();

  return v_tenant_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.current_tenant_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(
    nullif(auth.jwt()->>'tenant_id','')::uuid,
    nullif(current_setting('app.tenant_id', true),'')::uuid
  );
$function$
;

CREATE OR REPLACE FUNCTION public.deal_id_from_object_path(p_name text)
 RETURNS uuid
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select nullif(split_part(p_name, '/', 2), '')::uuid;
$function$
;

CREATE OR REPLACE FUNCTION public.deals_tc_same_tenant()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare
  c_tenant uuid;
begin
  if new.assigned_tc_contact_id is null then
    return new;
  end if;

  select tenant_id into c_tenant
  from public.contacts
  where id = new.assigned_tc_contact_id;

  if c_tenant is null or c_tenant <> new.tenant_id then
    raise exception 'assigned_tc_contact_id must belong to the same tenant as the deal';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_deal(p_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
  delete from public.deals
  where id = p_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.enforce_deals_row_version()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  -- Require row_version on UPDATE
  if new.row_version is null then
    raise exception 'row_version required';
  end if;

  -- Must match current version
  if new.row_version <> old.row_version then
    raise exception 'row_version mismatch (expected %, got %)', old.row_version, new.row_version;
  end if;

  -- Increment version
  new.row_version := old.row_version + 1;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_entitlements()
 RETURNS TABLE(user_id uuid, tenant_id uuid, subscription_tier text, subscription_status text, is_beta boolean, can_access boolean, can_write boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select
    e.user_id,
    e.tenant_id,
    e.subscription_tier::text,
    e.subscription_status::text,
    e.is_beta,
    e.can_access,
    e.can_write
  from public.entitlements_v e
  where e.user_id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.get_market_areas_by_token(p_token text)
 RETURNS TABLE(id uuid, area_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
begin
  select tpl.tenant_id
  into v_tenant_id
  from public.tenant_public_links tpl
  where tpl.token = p_token
    and tpl.is_active = true
    and (tpl.expires_at is null or tpl.expires_at > now());

  if v_tenant_id is null then
    return;
  end if;

  return query
  select tma.id, tma.area_name
  from public.tenant_market_areas tma
  where tma.tenant_id = v_tenant_id
  order by tma.area_name;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_seller_timeline_options_by_token(p_token text)
 RETURNS TABLE(id uuid, label text, sort_order integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
begin
  select tpl.tenant_id
  into v_tenant_id
  from public.tenant_public_links tpl
  where tpl.token = p_token
    and tpl.is_active = true
    and (tpl.expires_at is null or tpl.expires_at > now());

  if v_tenant_id is null then
    return;
  end if;

  return query
  select sto.id, sto.label, coalesce(sto.sort_order, 9999)
  from public.seller_timeline_options sto
  where sto.tenant_id = v_tenant_id
  order by coalesce(sto.sort_order, 9999), sto.label;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.user_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.join_workspace(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_tenant_id uuid;
begin
  select tenant_id
  into v_tenant_id
  from public.workspace_invites
  where code = p_code
    and (expires_at is null or expires_at > now());

  if v_tenant_id is null then
    raise exception 'Invalid or expired invite code';
  end if;

  insert into public.tenant_memberships (
    tenant_id,
    user_id,
    role
  )
  values (
    v_tenant_id,
    auth.uid(),
    'member'
  )
  on conflict do nothing;

  update public.user_profiles
  set current_tenant_id = v_tenant_id
  where user_id = auth.uid();

  return v_tenant_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.leave_workspace()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  update public.user_profiles
  set current_tenant_id = null
  where user_id = auth.uid();
end;
$function$
;

create or replace view "public"."my_deals" as  SELECT id,
    tenant_id,
    created_at,
    updated_at,
    market_area,
    property_address,
    postal_code,
    beds,
    baths,
    sqft,
    property_type,
    dwelling_type,
    parking,
    motivation,
    seller_timeline,
    notes,
    tags,
    condition_notes,
    repairs_required,
    repair_estimate,
    asking_price,
    mortgage_owing,
    arv,
    purchase_price,
    assignment_fee,
    wholesale_price,
    status AS stage,
    lead_source,
    calc_version,
    row_version,
    country_code,
    currency_code,
    measurement_unit,
    assigned_tc_contact_id
   FROM public.deals d
  WHERE (tenant_id = public.current_tenant_id());


create or replace view "public"."my_tenant_profile" as  SELECT id,
    billing_email,
    country_code,
    currency_code,
    measurement_unit,
    subscription_tier,
    created_at,
    trial_started_at,
    trial_ends_at,
    subscription_status,
    subscription_started_at,
    subscription_ends_at,
    canceled_at,
    locked_at,
    onboarding_completed_at,
    workspace_name
   FROM public.tenants t
  WHERE (id = public.current_tenant_id());


CREATE OR REPLACE FUNCTION public.remove_member(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid := current_tenant_id();
  v_is_owner boolean;
begin
  if v_tenant_id is null then
    raise exception 'No current tenant';
  end if;

  -- only an owner of the current tenant can remove members
  select exists (
    select 1
    from public.tenant_memberships tm
    where tm.tenant_id = v_tenant_id
      and tm.user_id = auth.uid()
      and tm.role = 'owner'
  ) into v_is_owner;

  if not v_is_owner then
    raise exception 'Not authorized';
  end if;

  -- remove membership (do not allow removing the owner via this function)
  delete from public.tenant_memberships
  where tenant_id = v_tenant_id
    and user_id = p_user_id
    and role <> 'owner';

  -- if they were actively attached to this tenant, detach them (kicks them to tenantless)
  update public.user_profiles
  set current_tenant_id = null
  where user_id = p_user_id
    and current_tenant_id = v_tenant_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_bootstrap_analyzer()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'market_areas', (
      select coalesce(jsonb_agg(to_jsonb(ma) order by ma.created_at), '[]'::jsonb)
      from public.tenant_market_areas ma
      where ma.tenant_id = public.current_tenant_id()
    )
  );
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_bootstrap_intake()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := public.current_tenant_id();

  return jsonb_build_object(
    'market_areas',
      coalesce(
        (select jsonb_agg(jsonb_build_object('area_name', m.area_name) order by m.area_name)
         from public.tenant_market_areas m
         where m.tenant_id = v_tenant_id),
        '[]'::jsonb
      ),

    'seller_timeline',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', s.label, 'sort_order', s.sort_order) order by s.sort_order)
         from public.seller_timeline_options s),
        '[]'::jsonb
      ),

    'deal_status',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', ds.label, 'sort_order', ds.sort_order) order by ds.sort_order)
         from public.deal_status_options ds),
        '[]'::jsonb
      ),

    'lead_source',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', src.label, 'sort_order', src.sort_order) order by src.sort_order)
         from public.lead_source_options src),
        '[]'::jsonb
      ),

    'contact_type',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', ct.label, 'sort_order', ct.sort_order) order by ct.sort_order)
         from public.contact_type_options ct),
        '[]'::jsonb
      ),

    'motivation',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', mo.label, 'sort_order', mo.sort_order) order by mo.sort_order)
         from public.motivation_options mo),
        '[]'::jsonb
      ),

    'tags',
      coalesce(
        (select jsonb_agg(jsonb_build_object('tag', t.tag) order by t.tag)
         from public.deal_tag_options t),
        '[]'::jsonb
      ),

    'property_type',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', p.label, 'sort_order', p.sort_order) order by p.sort_order)
         from public.property_type_options p),
        '[]'::jsonb
      ),

    'dwelling_style',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', d.label, 'sort_order', d.sort_order) order by d.sort_order)
         from public.dwelling_style_options d),
        '[]'::jsonb
      ),

    'repairs_required',
      coalesce(
        (select jsonb_agg(jsonb_build_object('label', r.label, 'sort_order', r.sort_order) order by r.sort_order)
         from public.repair_required_options r),
        '[]'::jsonb
      )
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_create_deal_intake(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
  v_id uuid;
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'no tenant';
  end if;

  insert into public.deals (
    tenant_id,
    property_address,
    market_area,
    motivation,
    seller_timeline,
    lead_source,
    status,
    notes,
    country_code,
    currency_code,
    measurement_unit,
    calc_version,
    row_version
  )
  values (
    v_tenant_id,
    nullif(trim(p->>'property_address'),''),
    nullif(trim(p->>'market_area'),''),
    nullif(trim(p->>'motivation'),''),
    nullif(trim(p->>'seller_timeline'),''),
    nullif(trim(p->>'lead_source'),''),
    coalesce(nullif(trim(p->>'status'),''), 'new'),
    nullif(trim(p->>'notes'),''),
    nullif(trim(p->>'country_code'),''),
    nullif(trim(p->>'currency_code'),''),
    nullif(trim(p->>'measurement_unit'),''),
    coalesce(nullif(trim(p->>'calc_version'),''), 'v1'),
    1
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'deal_id', v_id, 'row_version', 1);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_create_deal_intake_with_contact(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
  v_contact_id uuid;
  v_deal_id uuid;
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'no tenant';
  end if;

  insert into public.contacts (
    tenant_id, name, email, phone, contact_type, notes
  )
  values (
    v_tenant_id,
    nullif(trim(p->>'contact_name'),''),
    nullif(trim(p->>'contact_email'),''),
    nullif(trim(p->>'contact_phone'),''),
    nullif(trim(p->>'contact_type'),''),
    nullif(trim(p->>'contact_notes'),'')
  )
  returning id into v_contact_id;

  insert into public.deals (
    tenant_id,
    seller_contact_id,
    property_address,
    market_area,
    motivation,
    seller_timeline,
    lead_source,
    status,
    notes,
    calc_version,
    row_version
  )
  values (
    v_tenant_id,
    v_contact_id,
    nullif(trim(p->>'property_address'),''),
    nullif(trim(p->>'market_area'),''),
    nullif(trim(p->>'motivation'),''),
    nullif(trim(p->>'seller_timeline'),''),
    nullif(trim(p->>'lead_source'),''),
    coalesce(nullif(trim(p->>'status'),''), 'New'),
    nullif(trim(p->>'deal_notes'),''),
    coalesce(nullif(trim(p->>'calc_version'),''), 'v1'),
    1
  )
  returning id into v_deal_id;

  return jsonb_build_object(
    'ok', true,
    'contact_id', v_contact_id,
    'deal_id', v_deal_id,
    'row_version', 1
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_create_deal_manual(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
  v_id uuid;
  v_tags text[];
  v_repairs text[];
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'no tenant';
  end if;

  if p ? 'tags' then
    select array_agg(x) into v_tags
    from jsonb_array_elements_text(p->'tags') as t(x);
  end if;

  if p ? 'repairs_required' then
    select array_agg(x) into v_repairs
    from jsonb_array_elements_text(p->'repairs_required') as t(x);
  end if;

  insert into public.deals (
    tenant_id,
    property_address,
    market_area,
    postal_code,
    beds,
    baths,
    sqft,
    property_type,
    dwelling_type,
    parking,
    motivation,
    seller_timeline,
    notes,
    tags,
    repairs_required,
    repair_estimate,
    asking_price,
    mortgage_owing,
    arv,
    purchase_price,
    assignment_fee,
    wholesale_price,
    status,
    lead_source,
    country_code,
    currency_code,
    measurement_unit,
    assigned_tc_contact_id,
    calc_version,
    row_version
  )
  values (
    v_tenant_id,
    nullif(trim(p->>'property_address'),''),
    nullif(trim(p->>'market_area'),''),
    nullif(trim(p->>'postal_code'),''),
    (p->>'beds')::numeric,
    (p->>'baths')::numeric,
    (p->>'sqft')::numeric,
    nullif(trim(p->>'property_type'),''),
    nullif(trim(p->>'dwelling_type'),''),
    nullif(trim(p->>'parking'),''),
    nullif(trim(p->>'motivation'),''),
    nullif(trim(p->>'seller_timeline'),''),
    nullif(trim(p->>'notes'),''),
    v_tags,
    v_repairs,
    (p->>'repair_estimate')::numeric,
    (p->>'asking_price')::numeric,
    (p->>'mortgage_owing')::numeric,
    (p->>'arv')::numeric,
    (p->>'purchase_price')::numeric,
    (p->>'assignment_fee')::numeric,
    (p->>'wholesale_price')::numeric,
    coalesce(nullif(trim(p->>'status'),''), 'new'),
    nullif(trim(p->>'lead_source'),''),
    nullif(trim(p->>'country_code'),''),
    nullif(trim(p->>'currency_code'),''),
    nullif(trim(p->>'measurement_unit'),''),
    nullif(p->>'assigned_tc_contact_id','')::uuid,
    coalesce(nullif(trim(p->>'calc_version'),''), 'v1'),
    1
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'deal_id', v_id);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_echo_token(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_token is null or length(trim(p_token)) = 0 then
    raise exception 'missing token';
  end if;

  return jsonb_build_object(
    'ok', true,
    'token', p_token
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_get_deal(p_deal_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select to_jsonb(d)
  from public.deals d
  where d.id = p_deal_id
    and d.tenant_id = public.current_tenant_id();
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_get_market_areas_by_token(p_token text)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from public.get_market_areas_by_token(p_token) as t;
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_list_market_areas()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(to_jsonb(ma) order by ma.created_at), '[]'::jsonb)
  from public.tenant_market_areas ma
  where ma.tenant_id = public.current_tenant_id();
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_ping_auth()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select jsonb_build_object(
    'ok', true,
    'tenant_id', public.current_tenant_id()
  );
$function$
;

CREATE OR REPLACE FUNCTION public.rpc_reset_exec_grants_baseline()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE r record;
BEGIN
  -- authenticated gets execute on all functions
  REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM authenticated;
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

  -- anon gets nothing by default
  REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM anon;

  -- anon only on the 4 public/by-token RPCs
  GRANT EXECUTE ON FUNCTION public.get_market_areas_by_token(text) TO anon;
  GRANT EXECUTE ON FUNCTION public.get_seller_timeline_options_by_token(text) TO anon;
  GRANT EXECUTE ON FUNCTION public.rpc_get_market_areas_by_token(text) TO anon;
  GRANT EXECUTE ON FUNCTION public.submit_seller_form_by_token(text,uuid,text,text,text,jsonb) TO anon;

  -- make those 4 anon-only
  REVOKE EXECUTE ON FUNCTION public.get_market_areas_by_token(text) FROM authenticated;
  REVOKE EXECUTE ON FUNCTION public.get_seller_timeline_options_by_token(text) FROM authenticated;
  REVOKE EXECUTE ON FUNCTION public.rpc_get_market_areas_by_token(text) FROM authenticated;
  REVOKE EXECUTE ON FUNCTION public.submit_seller_form_by_token(text,uuid,text,text,text,jsonb) FROM authenticated;

  -- re-lock admin funcs for everyone except postgres/service_role
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN ('admin_set_subscription','apply_billing_event')
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM authenticated, anon;', r.sig);
  END LOOP;

  -- lock this reset RPC too
  REVOKE EXECUTE ON FUNCTION public.rpc_reset_exec_grants_baseline() FROM authenticated, anon;
END $function$
;

CREATE OR REPLACE FUNCTION public.rpc_update_deal_fields(p jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
  v_id uuid := nullif(p->>'deal_id','')::uuid;
  v_expected int := nullif(p->>'row_version','')::int;
  v_new_version int;

  v_tags text[];
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then raise exception 'no tenant'; end if;
  if v_id is null then raise exception 'missing deal_id'; end if;
  if v_expected is null then raise exception 'missing row_version'; end if;

  if p ? 'tags' then
    select array_agg(x) into v_tags
    from jsonb_array_elements_text(p->'tags') as t(x);
  end if;

  update public.deals d
  set
    property_address = coalesce(nullif(trim(p->>'property_address'),''), d.property_address),
    postal_code      = coalesce(nullif(trim(p->>'postal_code'),''), d.postal_code),
    market_area      = coalesce(nullif(trim(p->>'market_area'),''), d.market_area),

    beds = coalesce(nullif(trim(p->>'beds'),''), null)::numeric,
    baths = coalesce(nullif(trim(p->>'baths'),''), null)::numeric,
    sqft = coalesce(nullif(trim(p->>'sqft'),''), null)::numeric,

    property_type   = coalesce(nullif(trim(p->>'property_type'),''), d.property_type),
    dwelling_type   = coalesce(nullif(trim(p->>'dwelling_type'),''), d.dwelling_type),
    parking         = coalesce(nullif(trim(p->>'parking'),''), d.parking),
    motivation      = coalesce(nullif(trim(p->>'motivation'),''), d.motivation),
    seller_timeline = coalesce(nullif(trim(p->>'seller_timeline'),''), d.seller_timeline),

    repair_estimate = coalesce(nullif(trim(p->>'repair_estimate'),''), null)::numeric,
    asking_price    = coalesce(nullif(trim(p->>'asking_price'),''), null)::numeric,
    mortgage_owing  = coalesce(nullif(trim(p->>'mortgage_owing'),''), null)::numeric,
    arv             = coalesce(nullif(trim(p->>'arv'),''), null)::numeric,
    purchase_price  = coalesce(nullif(trim(p->>'purchase_price'),''), null)::numeric,
    assignment_fee  = coalesce(nullif(trim(p->>'assignment_fee'),''), null)::numeric,
    wholesale_price = coalesce(nullif(trim(p->>'wholesale_price'),''), null)::numeric,

    status      = coalesce(nullif(trim(p->>'status'),''), d.status),
    lead_source = coalesce(nullif(trim(p->>'lead_source'),''), d.lead_source),
    notes       = coalesce(nullif(trim(p->>'notes'),''), d.notes),
    calc_version= coalesce(nullif(trim(p->>'calc_version'),''), d.calc_version),

    tags = case when p ? 'tags' then v_tags else d.tags end,

    updated_at = now(),
    row_version = d.row_version + 1
  where d.id = v_id
    and d.tenant_id = v_tenant_id
    and d.row_version = v_expected
  returning row_version into v_new_version;

  if v_new_version is null then
    raise exception 'conflict (row_version)';
  end if;

  return jsonb_build_object('ok', true, 'deal_id', v_id, 'row_version', v_new_version);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_seller_form_by_token(p_token text, p_market_area_id uuid, p_seller_name text, p_seller_phone text, p_seller_email text, p_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_tenant_id uuid;
  v_id uuid;
begin
  select tpl.tenant_id
    into v_tenant_id
  from public.tenant_public_links tpl
  where tpl.token = p_token
    and tpl.is_active = true
    and (tpl.expires_at is null or tpl.expires_at > now());

  if v_tenant_id is null then
    return null;
  end if;

  insert into public.seller_submissions (
    tenant_id,
    market_area_id,
    seller_name,
    seller_phone,
    seller_email,
    payload
  )
  values (
    v_tenant_id,
    p_market_area_id,
    nullif(p_seller_name, ''),
    nullif(p_seller_phone, ''),
    nullif(p_seller_email, ''),
    coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;

  return v_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.tenant_write_allowed(p_tenant_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select exists (
    select 1
    from public.tenants t
    where t.id = p_tenant_id
      and coalesce(t.subscription_status,'active') not in ('locked','past_due')
  );
$function$
;

CREATE OR REPLACE FUNCTION public.trg_bump_row_version()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.row_version := old.row_version + 1;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.trg_deals_fill_locale_defaults()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  -- only fill if blank/null on the incoming row
  if new.country_code is null or btrim(new.country_code) = '' then
    select t.country_code into new.country_code
    from public.tenants t
    where t.id = new.tenant_id;
  end if;

  if new.currency_code is null or btrim(new.currency_code) = '' then
    select t.currency_code into new.currency_code
    from public.tenants t
    where t.id = new.tenant_id;
  end if;

  if new.measurement_unit is null or btrim(new.measurement_unit) = '' then
    select t.measurement_unit into new.measurement_unit
    from public.tenants t
    where t.id = new.tenant_id;
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.update_deal(p_id uuid, p_expected_row_version integer, p_patch jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_current_version int;
  v_notes text;
begin
  select d.row_version into v_current_version
  from public.deals d
  where d.id = p_id and d.tenant_id = v_tenant_id;

  if v_current_version is null then
    return jsonb_build_object('ok', false, 'code', 'NOT_FOUND', 'message', 'Deal not found');
  end if;

  if v_current_version <> p_expected_row_version then
    return jsonb_build_object(
      'ok', false,
      'code', 'ROW_VERSION_CONFLICT',
      'message', 'Deal was modified elsewhere',
      'details', jsonb_build_object('current_row_version', v_current_version)
    );
  end if;

  v_notes := nullif(p_patch->>'notes','');

  update public.deals d
  set
    notes = coalesce(v_notes, d.notes),
    updated_at = now()
  where d.id = p_id and d.tenant_id = v_tenant_id;

  insert into public.audit_log(tenant_id, user_id, action, entity_type, entity_id, meta)
  values (v_tenant_id, auth.uid(), 'update', 'deal', p_id, p_patch);

  return jsonb_build_object('ok', true, 'data', jsonb_build_object('id', p_id));
end;
$function$
;

create or replace view "public"."v_rpc_grants_health" as  SELECT ( SELECT count(*) AS count
           FROM information_schema.routine_privileges
          WHERE (((routine_privileges.routine_schema)::name = 'public'::name) AND ((routine_privileges.grantee)::name = 'anon'::name))) AS anon_fn_count,
    ( SELECT count(*) AS count
           FROM information_schema.routine_privileges
          WHERE (((routine_privileges.routine_schema)::name = 'public'::name) AND ((routine_privileges.grantee)::name = 'authenticated'::name))) AS auth_fn_count,
    ( SELECT count(*) AS count
           FROM information_schema.routine_privileges
          WHERE (((routine_privileges.routine_schema)::name = 'public'::name) AND ((routine_privileges.routine_name)::name = ANY (ARRAY['admin_set_subscription'::name, 'apply_billing_event'::name])) AND ((routine_privileges.grantee)::name = ANY (ARRAY['anon'::name, 'authenticated'::name])))) AS admin_leak_count,
    ( SELECT count(*) AS count
           FROM information_schema.table_privileges
          WHERE (((table_privileges.table_schema)::name = 'public'::name) AND ((table_privileges.table_name)::name = '_rpc_grants_snapshot'::name) AND ((table_privileges.grantee)::name = ANY (ARRAY['anon'::name, 'authenticated'::name])))) AS snapshot_leak_count,
    ( SELECT (count(*) = 4)
           FROM information_schema.routine_privileges
          WHERE (((routine_privileges.routine_schema)::name = 'public'::name) AND ((routine_privileges.grantee)::name = 'anon'::name))) AS anon_count_ok,
    ( SELECT (count(*) = 29)
           FROM information_schema.routine_privileges
          WHERE (((routine_privileges.routine_schema)::name = 'public'::name) AND ((routine_privileges.grantee)::name = 'authenticated'::name))) AS auth_count_ok;


create or replace view "public"."entitlements_v" as  SELECT tm.user_id,
    t.id AS tenant_id,
    t.subscription_tier,
    t.subscription_status,
    t.is_beta,
    ((t.subscription_status = ANY (ARRAY['trialing'::text, 'active'::text])) AND (t.subscription_tier = 'core'::public.subscription_tier)) AS can_access,
    public.tenant_write_allowed(t.id) AS can_write
   FROM (public.tenant_memberships tm
     JOIN public.tenants t ON ((t.id = tm.tenant_id)));


grant delete on table "public"."_rpc_grants_snapshot" to "service_role";

grant insert on table "public"."_rpc_grants_snapshot" to "service_role";

grant references on table "public"."_rpc_grants_snapshot" to "service_role";

grant select on table "public"."_rpc_grants_snapshot" to "service_role";

grant trigger on table "public"."_rpc_grants_snapshot" to "service_role";

grant truncate on table "public"."_rpc_grants_snapshot" to "service_role";

grant update on table "public"."_rpc_grants_snapshot" to "service_role";

grant delete on table "public"."audit_log" to "anon";

grant insert on table "public"."audit_log" to "anon";

grant references on table "public"."audit_log" to "anon";

grant select on table "public"."audit_log" to "anon";

grant trigger on table "public"."audit_log" to "anon";

grant truncate on table "public"."audit_log" to "anon";

grant update on table "public"."audit_log" to "anon";

grant delete on table "public"."audit_log" to "authenticated";

grant insert on table "public"."audit_log" to "authenticated";

grant references on table "public"."audit_log" to "authenticated";

grant select on table "public"."audit_log" to "authenticated";

grant trigger on table "public"."audit_log" to "authenticated";

grant truncate on table "public"."audit_log" to "authenticated";

grant update on table "public"."audit_log" to "authenticated";

grant delete on table "public"."audit_log" to "service_role";

grant insert on table "public"."audit_log" to "service_role";

grant references on table "public"."audit_log" to "service_role";

grant select on table "public"."audit_log" to "service_role";

grant trigger on table "public"."audit_log" to "service_role";

grant truncate on table "public"."audit_log" to "service_role";

grant update on table "public"."audit_log" to "service_role";

grant select on table "public"."deals" to "authenticated";

grant delete on table "public"."deals" to "service_role";

grant insert on table "public"."deals" to "service_role";

grant references on table "public"."deals" to "service_role";

grant select on table "public"."deals" to "service_role";

grant trigger on table "public"."deals" to "service_role";

grant truncate on table "public"."deals" to "service_role";

grant update on table "public"."deals" to "service_role";

grant delete on table "public"."tenant_memberships" to "anon";

grant insert on table "public"."tenant_memberships" to "anon";

grant references on table "public"."tenant_memberships" to "anon";

grant select on table "public"."tenant_memberships" to "anon";

grant trigger on table "public"."tenant_memberships" to "anon";

grant truncate on table "public"."tenant_memberships" to "anon";

grant update on table "public"."tenant_memberships" to "anon";

grant delete on table "public"."tenant_memberships" to "authenticated";

grant insert on table "public"."tenant_memberships" to "authenticated";

grant references on table "public"."tenant_memberships" to "authenticated";

grant select on table "public"."tenant_memberships" to "authenticated";

grant trigger on table "public"."tenant_memberships" to "authenticated";

grant truncate on table "public"."tenant_memberships" to "authenticated";

grant update on table "public"."tenant_memberships" to "authenticated";

grant delete on table "public"."tenant_memberships" to "service_role";

grant insert on table "public"."tenant_memberships" to "service_role";

grant references on table "public"."tenant_memberships" to "service_role";

grant select on table "public"."tenant_memberships" to "service_role";

grant trigger on table "public"."tenant_memberships" to "service_role";

grant truncate on table "public"."tenant_memberships" to "service_role";

grant update on table "public"."tenant_memberships" to "service_role";

grant delete on table "public"."tenants" to "anon";

grant insert on table "public"."tenants" to "anon";

grant references on table "public"."tenants" to "anon";

grant select on table "public"."tenants" to "anon";

grant trigger on table "public"."tenants" to "anon";

grant truncate on table "public"."tenants" to "anon";

grant update on table "public"."tenants" to "anon";

grant delete on table "public"."tenants" to "authenticated";

grant insert on table "public"."tenants" to "authenticated";

grant references on table "public"."tenants" to "authenticated";

grant select on table "public"."tenants" to "authenticated";

grant trigger on table "public"."tenants" to "authenticated";

grant truncate on table "public"."tenants" to "authenticated";

grant update on table "public"."tenants" to "authenticated";

grant delete on table "public"."tenants" to "service_role";

grant insert on table "public"."tenants" to "service_role";

grant references on table "public"."tenants" to "service_role";

grant select on table "public"."tenants" to "service_role";

grant trigger on table "public"."tenants" to "service_role";

grant truncate on table "public"."tenants" to "service_role";

grant update on table "public"."tenants" to "service_role";


  create policy "_rpc_grants_snapshot_service_only"
  on "public"."_rpc_grants_snapshot"
  as restrictive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "audit_log_select_own_tenant"
  on "public"."audit_log"
  as permissive
  for select
  to authenticated
using ((tenant_id = public.current_tenant_id()));



  create policy "deals_delete_own"
  on "public"."deals"
  as permissive
  for delete
  to authenticated
using (((tenant_id = public.current_tenant_id()) AND (public.can_write_current_tenant() = true)));



  create policy "deals_insert_own"
  on "public"."deals"
  as permissive
  for insert
  to authenticated
with check (((tenant_id = public.current_tenant_id()) AND (public.can_write_current_tenant() = true)));



  create policy "deals_select_own"
  on "public"."deals"
  as permissive
  for select
  to authenticated
using ((tenant_id = public.current_tenant_id()));



  create policy "deals_update_own"
  on "public"."deals"
  as permissive
  for update
  to authenticated
using (((tenant_id = public.current_tenant_id()) AND (public.can_write_current_tenant() = true)))
with check (((tenant_id = public.current_tenant_id()) AND (public.can_write_current_tenant() = true)));



  create policy "memberships_insert_self"
  on "public"."tenant_memberships"
  as permissive
  for insert
  to authenticated
with check ((user_id = auth.uid()));



  create policy "memberships_select_own"
  on "public"."tenant_memberships"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "tenant_owner_admin_update"
  on "public"."tenants"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tenant_memberships tm
  WHERE ((tm.user_id = auth.uid()) AND (tm.tenant_id = tenants.id) AND (tm.role = ANY (ARRAY['owner'::text, 'admin'::text]))))))
with check ((EXISTS ( SELECT 1
   FROM public.tenant_memberships tm
  WHERE ((tm.user_id = auth.uid()) AND (tm.tenant_id = tenants.id) AND (tm.role = ANY (ARRAY['owner'::text, 'admin'::text]))))));



  create policy "tenants_select_if_member"
  on "public"."tenants"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.tenant_memberships tm
  WHERE ((tm.tenant_id = tenants.id) AND (tm.user_id = auth.uid())))));


CREATE TRIGGER bump_row_version BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.trg_bump_row_version();

CREATE TRIGGER deals_fill_locale_defaults BEFORE INSERT ON public.deals FOR EACH ROW EXECUTE FUNCTION public.trg_deals_fill_locale_defaults();

CREATE TRIGGER trg_deals_tc_same_tenant BEFORE INSERT OR UPDATE OF assigned_tc_contact_id, tenant_id ON public.deals FOR EACH ROW EXECUTE FUNCTION public.deals_tc_same_tenant();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();


  create policy "deal_media_delete"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'deal_media'::text) AND (EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = public.deal_id_from_object_path(objects.name)) AND (d.tenant_id = public.current_tenant_id()))))));



  create policy "deal_media_insert"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'deal_media'::text) AND (EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = public.deal_id_from_object_path(objects.name)) AND (d.tenant_id = public.current_tenant_id()))))));



  create policy "deal_media_read"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'deal_media'::text) AND (EXISTS ( SELECT 1
   FROM public.deals d
  WHERE ((d.id = public.deal_id_from_object_path(objects.name)) AND (d.tenant_id = public.current_tenant_id()))))));



