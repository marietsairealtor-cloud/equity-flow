import { supabaseServer } from "@/lib/supabase/server";
import MembersUI from "./ui";

type MemberRow = {
  user_id: string;
  email: string | null;
  role: string;
};

export default async function MembersPage() {
  const supabase = await supabaseServer();
  const ent = await supabase.rpc("get_entitlements");
  const e = ent.data?.[0];

  const tenantId = (e?.tenant_id as string | null) ?? null;
  const workspaceName = (e?.workspace_name as string | null) ?? null;

  let members: MemberRow[] = [];
  if (tenantId) {
    const m = await supabase.rpc("get_tenant_members", { p_tenant_id: tenantId });
    members = (m.data ?? []) as MemberRow[];
  }

  return <MembersUI tenantId={tenantId} workspaceName={workspaceName} initialMembers={members} />;
}