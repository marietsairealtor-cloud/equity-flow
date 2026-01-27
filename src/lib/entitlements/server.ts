import { supabaseServer } from "@/lib/supabase/server";

export type EntitlementRow = {
  tenant_id: string;
  workspace_name: string | null;
  role: string;
  tier: string;
  status: string;
  trial_ends_at: string | null;
};

function computeEffective(tenant: any) {
  const now = new Date();
  const ts = tenant?.trial_started_at ? new Date(tenant.trial_started_at) : null;
  const te = tenant?.trial_ends_at ? new Date(tenant.trial_ends_at) : null;
  const trialActive = !!(ts && te && now < te);

  return {
    tier: trialActive ? "core" : (tenant?.subscription_tier ?? "free"),
    status: trialActive ? "trialing" : (tenant?.subscription_status ?? "pending"),
    trial_ends_at: tenant?.trial_ends_at ?? null,
  };
}

export async function getEntitlementsServer(): Promise<EntitlementRow[]> {
  const supabase = await supabaseServer();

  const { data: u } = await supabase.auth.getUser();
  if (!u?.user) return [];

  const m = await supabase
    .from("tenant_memberships")
    .select("tenant_id, role, created_at")
    .eq("user_id", u.user.id)
    .order("created_at", { ascending: false });

  if (m.error || !m.data?.length) return [];

  const tenantIds = m.data.map(x => x.tenant_id);

  const t = await supabase
    .from("tenants")
    .select("id, workspace_name, subscription_status, subscription_tier, trial_started_at, trial_ends_at")
    .in("id", tenantIds);

  if (t.error || !t.data) return [];

  const byId = new Map<string, any>();
  for (const row of t.data) byId.set(row.id, row);

  return m.data.map(mem => {
    const tenant = byId.get(mem.tenant_id) ?? {};
    const eff = computeEffective(tenant);

    return {
      tenant_id: mem.tenant_id,
      workspace_name: tenant.workspace_name ?? null,
      role: mem.role,
      tier: eff.tier,
      status: eff.status,
      trial_ends_at: eff.trial_ends_at,
    };
  });
}