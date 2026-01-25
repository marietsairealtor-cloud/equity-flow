import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

type EntRow = {
  tenant_id: string | null;
  workspace_name: string | null;
  role: string | null;
  tier: string | null;
  status: "pending" | "trialing" | "active" | "past_due" | "canceled" | "locked" | string;
  trial_ends_at: string | null;
};

export default async function GatePage() {
  const supabase = await supabaseServer();
  const { data, error } = await supabase.rpc("get_entitlements");

  if (error) redirect("/login");

  const ent = (data?.[0] as EntRow | undefined);

  if (!ent?.tenant_id) redirect("/app/workspace");

  if (ent.status === "locked") redirect("/app/locked");
  if (ent.status === "past_due" || ent.status === "canceled") redirect("/app/billing");
  if (ent.status === "pending") redirect("/app/billing");
  if (ent.status === "trialing" || ent.status === "active") redirect("/app/home");

  redirect("/app/billing");
}

