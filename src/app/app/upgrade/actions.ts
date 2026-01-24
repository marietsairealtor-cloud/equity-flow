"use server";

import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

type State = { ok: boolean; error?: string };

type EntRow = {
  tenant_id: string | null;
  workspace_name: string | null;
  status: string | null;
};

export async function upgradeAndSave(prevState: State, formData: FormData): Promise<State> {
  const supabase = await supabaseServer();

  // Read current tenant/workspace for defaults + start_trial targeting
  const entRes = await supabase.rpc("get_entitlements");
  if (entRes.error) return { ok: false, error: entRes.error.message || "ENTITLEMENTS_FAILED" };

  const ent = (entRes.data?.[0] as EntRow | undefined);
  const tenant_id = ent?.tenant_id ?? null;

  const workspace_name_in = String(formData.get("workspace_name") ?? "").trim();
  const workspace_name = workspace_name_in || (ent?.workspace_name ?? "").trim() || "Workspace";

  const first_deal_raw = String(formData.get("first_deal_json") ?? "").trim();

  let first_deal: any = {};
  if (first_deal_raw) {
    try {
      first_deal = JSON.parse(first_deal_raw);
    } catch {
      return { ok: false, error: "FIRST_DEAL_JSON_INVALID" };
    }
  }

  const prov = await supabase.rpc("provision_upgrade_save", {
    p_workspace_name: workspace_name,
    p_first_deal: first_deal,
  });

  if (prov.error) return { ok: false, error: prov.error.message || "PROVISION_FAILED" };

  // Ensure status becomes trialing (auto-start trial). Safe if already trialing/active.
  if (tenant_id) {
    const trial = await supabase.rpc("start_trial", { p_tenant_id: tenant_id });
    // ignore errors that indicate no-op; surface others
    if (trial.error) {
      const msg = trial.error.message || "";
      if (!(msg.includes("ALREADY") || msg.includes("trial") || msg.includes("TRIAL"))) {
        return { ok: false, error: trial.error.message || "START_TRIAL_FAILED" };
      }
    }
  }

  redirect("/app/gate");
}
