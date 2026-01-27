import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

async function trySetCurrentTenant(supabase: any, tenantId: string) {
  const attempts: Array<{ fn: string; args: any }> = [
    { fn: "set_current_tenant", args: { p_tenant_id: tenantId } },
    { fn: "set_current_tenant", args: { tenant_id: tenantId } },
    { fn: "set_current_tenant_rpc", args: { p_tenant_id: tenantId } },
    { fn: "set_current_tenant_rpc", args: { tenant_id: tenantId } },
  ];
  for (const a of attempts) {
    const r = await supabase.rpc(a.fn, a.args);
    if (!r.error) return;
  }
}

function isNextRedirect(e: any): boolean {
  const msg = (e?.message ?? "").toString();
  const digest = (e?.digest ?? "").toString();
  return msg.includes("NEXT_REDIRECT") || digest.includes("NEXT_REDIRECT");
}

function errToString(e: any): string {
  if (!e) return "UNKNOWN";
  if (typeof e === "string") return e;
  if (e.message && typeof e.message === "string") return e.message;
  if (e.details || e.hint || e.code) {
    try { return JSON.stringify(e); } catch {}
  }
  try { return JSON.stringify(e); } catch { return String(e); }
}

function computeEffective(tenant: any) {
  const now = new Date();
  const ts = tenant?.trial_started_at ? new Date(tenant.trial_started_at) : null;
  const te = tenant?.trial_ends_at ? new Date(tenant.trial_ends_at) : null;

  const trialActive = !!(ts && te && now < te);

  const tier = trialActive ? "core" : (tenant?.subscription_tier ?? "free");
  const status = trialActive ? "trialing" : (tenant?.subscription_status ?? "pending");

  return { trialActive, tier, status };
}

async function startTrialDirect(supabase: any, tenantId: string) {
  // Disambiguate overloaded start_trial() if needed
  const r1 = await supabase.rpc("start_trial", { p_tenant_id: tenantId, p_days: 14 });
  if (!r1.error) return;

  const msg1 = (r1.error?.message ?? "").toString();
  if (
    msg1.includes("Could not find the function public.start_trial(p_tenant_id, p_days)") ||
    msg1.includes("Could not find the function public.start_trial(p_tenant_id => uuid, p_days => integer)")
  ) {
    const r2 = await supabase.rpc("start_trial", { p_tenant_id: tenantId });
    if (!r2.error) return;
    throw r2.error;
  }

  throw r1.error;
}

export default async function UpgradePage(props: { searchParams?: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = (await props.searchParams) ?? {};
  const errRaw = sp.err;
  const errParam = Array.isArray(errRaw) ? errRaw[0] : errRaw;

  const supabase = await supabaseServer();

  const { data: u } = await supabase.auth.getUser();
  const user = u?.user;
  if (!user) redirect("/login");

  const m = await supabase
    .from("tenant_memberships")
    .select("tenant_id, role")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (m.error || !m.data?.tenant_id) redirect("/app/workspace");

  const tenantId = m.data.tenant_id as string;
  const role = (m.data.role ?? "").toString().toLowerCase();

  const t = await supabase
    .from("tenants")
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .eq("id", tenantId)
    .maybeSingle();

  if (t.error || !t.data) redirect("/app/workspace");

  const tenant = t.data;
  const eff = computeEffective(tenant);

  async function continueFreeAction() {
    "use server";
    let err: any = null;

    try {
      const supabase = await supabaseServer();
      await trySetCurrentTenant(supabase, tenantId);

      const up = await supabase
        .from("tenants")
        .update({ subscription_status: "active", subscription_tier: "free" })
        .eq("id", tenantId);

      if (up.error) throw up.error;
    } catch (e: any) {
      if (isNextRedirect(e)) throw e;
      err = e;
    }

    if (err) redirect(`/app/upgrade?err=${encodeURIComponent(errToString(err))}`);
    redirect("/app/home");
  }

  async function startTrialAction() {
    "use server";
    let err: any = null;

    try {
      const supabase = await supabaseServer();
      await trySetCurrentTenant(supabase, tenantId);

      const cur = await supabase
        .from("tenants")
        .select("trial_started_at")
        .eq("id", tenantId)
        .maybeSingle();

      if (cur.error) throw cur.error;
      if ((cur.data as any)?.trial_started_at) throw new Error("TRIAL_ALREADY_USED");

      await startTrialDirect(supabase, tenantId);
    } catch (e: any) {
      if (isNextRedirect(e)) throw e;
      err = e;
    }

    if (err) redirect(`/app/upgrade?err=${encodeURIComponent(errToString(err))}`);
    redirect("/app/home");
  }

  const isOwner = role === "owner";

  return (
    <div style={{ background: "#000", color: "#fff", minHeight: "100vh" }}>
      <div style={{ padding: 24, maxWidth: 820 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 12 }}>Upgrade</h1>

        {errParam ? (
          <div style={{ padding: 12, border: "1px solid #ff6b6b", borderRadius: 8, background: "#1a0000", marginBottom: 16 }}>
            <b style={{ color: "#fff" }}>Error:</b>{" "}
            <span style={{ fontFamily: "monospace", color: "#fff" }}>{decodeURIComponent(String(errParam))}</span>
          </div>
        ) : null}

        <div style={{ marginBottom: 16, lineHeight: 1.7 }}>
          <div><b>Workspace:</b> {tenant.workspace_name ?? "(unnamed)"}</div>
          <div><b>Effective status:</b> {eff.status}</div>
          <div><b>Effective tier:</b> {eff.tier}</div>
          <div><b>DB status:</b> {tenant.subscription_status}</div>
          <div><b>DB tier:</b> {tenant.subscription_tier}</div>
          {tenant.trial_ends_at ? <div><b>Trial ends:</b> {tenant.trial_ends_at}</div> : null}
          {tenant.trial_started_at ? (
            <div><b>Trial used:</b> yes (<span style={{ fontFamily: "monospace" }}>TRIAL_ALREADY_USED</span>)</div>
          ) : (
            <div><b>Trial used:</b> no</div>
          )}
        </div>

        {!isOwner ? (
          <div>Only the workspace owner can start a trial or change plans.</div>
        ) : (
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
            <form action={continueFreeAction}>
              <button
                type="submit"
                style={{
                  padding: "10px 14px",
                  borderRadius: 10,
                  border: "1px solid #444",
                  background: "#111",
                  color: "#fff",
                  cursor: "pointer",
                  fontWeight: 600,
                }}
              >
                Continue Free
              </button>
            </form>

            <form action={startTrialAction}>
              <button
                type="submit"
                style={{
                  padding: "10px 14px",
                  borderRadius: 10,
                  border: "1px solid #444",
                  background: "#111",
                  color: "#fff",
                  cursor: "pointer",
                  fontWeight: 600,
                }}
              >
                Start 14-day Trial (Core)
              </button>
            </form>
          </div>
        )}

        <div style={{ marginTop: 18, opacity: 0.85 }}>
          Free = allowed. Trial = 14 days of Core, one-time per workspace.
        </div>
      </div>
    </div>
  );
}