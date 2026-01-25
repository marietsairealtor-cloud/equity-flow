import { supabaseServer } from "@/lib/supabase/server";
import WorkspaceUI from "./ui";

export const dynamic = "force-dynamic";
export const revalidate = 0;

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

  // force dynamic + confirm session exists
  const me = await supabase.auth.getUser();

  const w = await supabase.rpc("get_my_workspaces");

  const workspaces = (w.data ?? []) as Ws[];
  const serverError =
    me.error?.message ??
    w.error?.message ??
    null;

  return <WorkspaceUI workspaces={workspaces} serverError={serverError} />;
}