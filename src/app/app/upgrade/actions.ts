"use server";

import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

export async function upgradeAndSave(formData: FormData) {
  const supabase = await supabaseServer();

  const { data: userData } = await supabase.auth.getUser();
  if (!userData?.user) redirect("/login");

  const workspace_name = String(formData.get("workspace_name") ?? "").trim();
  if (!workspace_name) redirect("/app/deals?err=WORKSPACE_NAME_REQUIRED");

  const first_deal = { status: "New", market_area: "default" };
  const idempotency_key =
    String(formData.get("idempotency_key") ?? "").trim() || ("W3-" + crypto.randomUUID());

  const { data, error } = await supabase.rpc("provision_upgrade_save", {
    p_first_deal: first_deal,
    p_idempotency_key: idempotency_key,
    p_workspace_name: workspace_name,
  });

  if (error) {
    redirect("/app/deals?err=" + encodeURIComponent("UPGRADE_SAVE_FAILED: " + error.message));
  }

  const row = Array.isArray(data) ? data[0] : null;
  if (!row?.tenant_id || !row?.deal_id) {
    redirect("/app/deals?err=UPGRADE_SAVE_BAD_RESPONSE");
  }

  // set_current_tenant param-name safe: try p_tenant_id then tenant_id
  const first = await supabase.rpc("set_current_tenant", { p_tenant_id: row.tenant_id });
  if (first.error) {
    const second = await supabase.rpc("set_current_tenant", { tenant_id: row.tenant_id });
    if (second.error) {
      redirect("/app/deals?err=" + encodeURIComponent("SET_TENANT_FAILED: " + second.error.message));
    }
  }

  redirect(`/app/deals/${row.deal_id}`);
}