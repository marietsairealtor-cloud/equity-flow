import { redirect } from "next/navigation";
import UpgradeForm from "./UpgradeForm";
import { supabaseServer } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function UpgradePage() {
  const supabase = await supabaseServer();
  const { data } = await supabase.rpc("get_entitlements");
  const ent = Array.isArray(data) ? data[0] : null;
  const status = String(ent?.status ?? "");

  // Upgrade is only for users who are pending (no trial started yet).
  if (status && status !== "pending") {
    redirect("/app/home");
  }

  return (
    <main style={{ padding: 24, display: "grid", gap: 16 }}>
      <h1 style={{ margin: 0, fontSize: 22 }}>Upgrade</h1>
      <UpgradeForm />
    </main>
  );
}