import { supabaseServer } from "@/lib/supabase/server";
import WorkspaceUI from "./ui";

type Ws = {
  tenant_id: string;
  workspace_name: string | null;
  role: string;
  tier: string;
  status: string;
  trial_ends_at: string | null;
};

export default async function WorkspacePage() {
  const supabase = await supabaseServer();

  // list all workspaces (does not rely on current_tenant_id)
  const w = await supabase.rpc("get_my_workspaces");
  const workspaces = (w.data ?? []) as Ws[];

  return <WorkspaceUI workspaces={workspaces} />;
}