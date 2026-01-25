import { supabaseServer } from "@/lib/supabase/server";
import InvitesClient from "./ui";

type InviteRow = {
  id: string;
  email: string;
  role: string;
  status: string;
  token: string | null;
  created_at: string;
};

export default async function InvitesPage() {
  const supabase = await supabaseServer();

  const ent = await supabase.rpc("get_entitlements");
  const tenantId = (ent.data?.[0]?.tenant_id as string | null) ?? null;
  const workspaceName = (ent.data?.[0]?.workspace_name as string | null) ?? "";

  if (!tenantId) {
    return (
      <div style={{ padding: 16 }}>
        <div style={{ fontSize: 20, fontWeight: 800 }}>Invites</div>
        <div style={{ marginTop: 10, fontSize: 13, color: "#444" }}>No workspace selected.</div>
        <a href="/app/workspace" style={{ fontSize: 13 }}>Go to Workspace</a>
      </div>
    );
  }

  const seats = await supabase.rpc("get_current_tenant_seats");
  const seatLimit = Number(seats.data?.[0]?.seat_limit ?? 0);
  const seatCount = Number(seats.data?.[0]?.seat_count ?? 0);

  const inv = await supabase
    .from("tenant_invites")
    .select("id,email,role,status,token,created_at")
    .eq("tenant_id", tenantId)
    .order("created_at", { ascending: false });

  return (
    <InvitesClient
      tenantId={tenantId}
      workspaceName={workspaceName ?? ""}
      seatLimit={seatLimit}
      seatCount={seatCount}
      initialInvites={(inv.data ?? []) as any[]}
    />
  );
}