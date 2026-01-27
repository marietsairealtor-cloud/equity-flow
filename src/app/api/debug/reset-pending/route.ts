import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

async function trySetCurrentTenant(supabase: any, tenantId: string) {
  const attempts: Array<{ fn: string; args: any }> = [
    { fn: "set_current_tenant", args: { tenant_id: tenantId } },
    { fn: "set_current_tenant", args: { p_tenant_id: tenantId } },
    { fn: "set_current_tenant_rpc", args: { tenant_id: tenantId } },
    { fn: "set_current_tenant_rpc", args: { p_tenant_id: tenantId } },
  ];
  for (const a of attempts) {
    const r = await supabase.rpc(a.fn, a.args);
    if (!r.error) return { ok: true, used: a.fn, args: a.args };
  }
  return { ok: false };
}

export async function GET() {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ ok: false, error: "DISABLED_IN_PROD" }, { status: 403 });
  }
  return NextResponse.json({ ok: true, hint: "POST here to force current tenant -> pending" });
}

export async function POST() {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ ok: false, error: "DISABLED_IN_PROD" }, { status: 403 });
  }

  const supabase = await supabaseServer();

  const ent = await supabase.rpc("get_entitlements");
  if (ent.error) return NextResponse.json({ ok: false, where: "get_entitlements", error: ent.error.message }, { status: 500 });

  const row = Array.isArray(ent.data) ? ent.data[0] : null;
  const tenantId = row?.tenant_id as string | undefined;
  if (!tenantId) return NextResponse.json({ ok: false, error: "NO_TENANT" }, { status: 400 });

  const setCtx = await trySetCurrentTenant(supabase, tenantId);

  const before = await supabase
    .from("tenants")
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .eq("id", tenantId)
    .maybeSingle();

  const up = await supabase
    .from("tenants")
    .update({ subscription_status: "pending", trial_started_at: null, trial_ends_at: null })
    .eq("id", tenantId)
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .maybeSingle();

  const after = await supabase
    .from("tenants")
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .eq("id", tenantId)
    .maybeSingle();

  return NextResponse.json({
    ok: !up.error,
    tenantId,
    set_current_tenant: setCtx,
    before: { data: before.data ?? null, error: before.error?.message ?? null },
    update: { data: up.data ?? null, error: up.error?.message ?? null },
    after: { data: after.data ?? null, error: after.error?.message ?? null },
    next: "/app/gate"
  }, { status: up.error ? 500 : 200 });
}