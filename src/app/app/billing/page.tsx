import { supabaseServer } from "@/lib/supabase/server";
import BillingClient from "./ui";

export default async function BillingPage() {
  const supabase = await supabaseServer();
  const ent = await supabase.rpc("get_entitlements");
  const e = ent.data?.[0];

  return (
    <BillingClient
      status={(e?.status as string) ?? "-"}
      tier={(e?.tier as string) ?? "-"}
      workspaceName={(e?.workspace_name as string) ?? ""}
      trialEndsAt={(e?.trial_ends_at as string) ?? null}
    />
  );
}