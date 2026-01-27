import { supabaseServer } from "@/lib/supabase/server";

function computeEffective(tenant: any) {
  const now = new Date();
  const ts = tenant?.trial_started_at ? new Date(tenant.trial_started_at) : null;
  const te = tenant?.trial_ends_at ? new Date(tenant.trial_ends_at) : null;

  const trialActive = !!(ts && te && now < te);

  const tier = trialActive ? "core" : (tenant?.subscription_tier ?? "free");
  const status = trialActive ? "trialing" : (tenant?.subscription_status ?? "pending");

  return { trialActive, tier, status };
}

export default async function TenantStatusPage() {
  const supabase = await supabaseServer();

  const { data: u } = await supabase.auth.getUser();
  const user = u?.user ?? null;

  let membership: any = null;
  let tenant: any = null;
  let err: any = null;

  if (!user) {
    err = { where: "auth.getUser", message: "NO_USER" };
  } else {
    const m = await supabase
      .from("tenant_memberships")
      .select("tenant_id, role")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (m.error) err = { where: "tenant_memberships", message: m.error.message };
    membership = m.data ?? null;

    if (membership?.tenant_id) {
      const t = await supabase
        .from("tenants")
        .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
        .eq("id", membership.tenant_id)
        .maybeSingle();

      if (t.error) err = { where: "tenants", message: t.error.message };
      tenant = t.data ?? null;
    }
  }

  const eff = tenant ? computeEffective(tenant) : null;

  return (
    <main style={{ padding: 24, maxWidth: 900 }}>
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>Tenant status (debug)</h1>

      <div style={{ marginTop: 12 }}>
        <a href="/app/debug/pending-test">/app/debug/pending-test</a>{" | "}
        <a href="/app/gate">/app/gate</a>{" | "}
        <a href="/app/home">/app/home</a>
      </div>

      <h2 style={{ marginTop: 18, fontSize: 16, fontWeight: 700 }}>auth</h2>
      <pre style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8, overflowX: "auto" }}>
        {JSON.stringify({ user_id: user?.id ?? null, error: err?.where === "auth.getUser" ? err : null }, null, 2)}
      </pre>

      <h2 style={{ marginTop: 18, fontSize: 16, fontWeight: 700 }}>membership</h2>
      <pre style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8, overflowX: "auto" }}>
        {JSON.stringify({ error: err?.where === "tenant_memberships" ? err : null, data: membership }, null, 2)}
      </pre>

      <h2 style={{ marginTop: 18, fontSize: 16, fontWeight: 700 }}>tenant</h2>
      <pre style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8, overflowX: "auto" }}>
        {JSON.stringify({ error: err?.where === "tenants" ? err : null, data: tenant, effective: eff }, null, 2)}
      </pre>
    </main>
  );
}