import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";
import StartTrialButton from "./StartTrialButton";

export default async function AppHomePage() {
  const supabase = await createSupabaseServerClient();

  const { data, error } = await supabase.rpc("get_entitlements");
  if (error) redirect("/login");

  const e = Array.isArray(data) ? data[0] : (data as any);
  if (!e) redirect("/app/workspace");

  const canStartTrial = e.role === "owner" || e.role === "admin";
  const showStartTrial = canStartTrial && (e.status === "pending" || e.status === "trialing");

  return (
    <div style={{ padding: 16, display: "grid", gap: 12 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>App</div>

      <ul>
        <li>Workspace: {e.workspace_name ?? "-"}</li>
        <li>role: {e.role}</li>
        <li>tier: {e.tier}</li>
        <li>status: {e.status}</li>
        <li>trial_ends_at: {e.trial_ends_at ?? "-"}</li>
      </ul>

      {showStartTrial ? <StartTrialButton tenantId={e.tenant_id} /> : null}
    </div>
  );
}

