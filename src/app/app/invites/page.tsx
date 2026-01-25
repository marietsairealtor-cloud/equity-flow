import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";
import InvitesClient from "./invites-client";

export default async function InvitesPage() {
  const supabase = await supabaseServer();

  const { data: userRes } = await supabase.auth.getUser();
  if (!userRes?.user) redirect("/login");

  const { data: ent, error: entErr } = await supabase.rpc("get_entitlements");
  const row = Array.isArray(ent) && ent.length > 0 ? ent[0] : null;

  if (entErr || !row?.tenant_id) redirect("/app/workspace");

  return <InvitesClient tenant_id={row.tenant_id} workspace_name={row.workspace_name ?? ""} role={row.role ?? ""} />;
}