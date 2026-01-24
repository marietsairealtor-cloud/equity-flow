import UpgradeForm from "./UpgradeForm";
import { supabaseServer } from "@/lib/supabase/server";

type EntRow = {
  workspace_name: string | null;
  status: string | null;
};

export default async function UpgradePage() {
  const supabase = await supabaseServer();
  const { data } = await supabase.rpc("get_entitlements");
  const ent = (data?.[0] as EntRow | undefined);

  return <UpgradeForm defaultWorkspaceName={ent?.workspace_name ?? ""} status={ent?.status ?? ""} />;
}
