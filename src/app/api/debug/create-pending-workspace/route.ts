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

async function tryCreateWorkspace(supabase: any, name: string) {
  const attempts: Array<{ fn: string; args: any }> = [
    { fn: "create_workspace", args: { workspace_name: name } },
    { fn: "create_workspace", args: { p_workspace_name: name } },
    { fn: "create_workspace_rpc", args: { workspace_name: name } },
    { fn: "create_workspace_rpc", args: { p_workspace_name: name } },
  ];

  for (const a of attempts) {
    const r = await supabase.rpc(a.fn, a.args);
    if (!r.error) return { ok: true, used: a.fn, args: a.args, data: r.data };
  }
  return { ok: false };
}

function extractTenantId(createResult: any): string | null {
  const d = createResult?.data;
  if (!d) return null;
  if (typeof d === "string" && d.length >= 30) return d;
  if (Array.isArray(d) && d[0]?.tenant_id) return d[0].tenant_id;
  if (d?.tenant_id) return d.tenant_id;
  if (d?.id) return d.id;
  return null;
}

export async function POST(req: Request) {
  if (process.env.NODE_ENV === "production") {
    return NextResponse.json({ ok: false, error: "DISABLED_IN_PROD" }, { status: 403 });
  }

  const supabase = await supabaseServer();

  const name = `PENDING_TEST_${new Date().toISOString().replace(/[:.]/g, "-")}`;
  const created = await tryCreateWorkspace(supabase, name);
  if (!created.ok) {
    return NextResponse.json({ ok: false, where: "create_workspace", created }, { status: 500 });
  }

  const tenantId = extractTenantId(created);
  if (!tenantId) {
    return NextResponse.json({ ok: false, where: "extractTenantId", created }, { status: 500 });
  }

  const setCtx = await trySetCurrentTenant(supabase, tenantId);

  // As owner, you should be allowed to update your new tenant
  const up = await supabase
    .from("tenants")
    .update({ subscription_status: "pending", trial_started_at: null, trial_ends_at: null })
    .eq("id", tenantId)
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .maybeSingle();

  if (up.error) {
    return NextResponse.json({ ok: false, where: "update_tenants", tenantId, set_current_tenant: setCtx, error: up.error.message }, { status: 500 });
  }

  // Redirect to gate to verify pending -> upgrade behavior
  return NextResponse.redirect(new URL("/app/gate?forced=pending_new", req.url));
}