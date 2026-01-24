import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";
import CreateInviteForm from "./CreateInviteForm";
import RevokeButton from "./RevokeButton";

type SearchParams = { show?: string };

export default async function InvitesPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const supabase = await createSupabaseServerClient();

  const { data: ent, error: entErr } = await supabase.rpc("get_entitlements");
  if (entErr) redirect("/login");

  const entRow = Array.isArray(ent) ? ent[0] : (ent as any);
  const workspaceName = (entRow as any)?.workspace_name ?? "-";
  const tenantId = entRow?.tenant_id as string | undefined;

  if (!tenantId) redirect("/app/workspace");

  const sp = await searchParams;
  const showHistory = sp?.show === "all";

  let q = supabase
    .from("tenant_invites")
    .select("id, invited_email, invited_role, created_at, expires_at, accepted_at, revoked_at")
    .eq("tenant_id", tenantId)
    .order("created_at", { ascending: false });

  if (!showHistory) {
    q = q.is("accepted_at", null).is("revoked_at", null);
  }

  const { data: invites, error: invErr } = await q;

  return (
    <div style={{ padding: 16, display: "grid", gap: 16 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>Invites</div>

      <CreateInviteForm tenantId={tenantId} workspaceName={workspaceName} />

      <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
        <a
          href={showHistory ? "/app/invites" : "/app/invites?show=all"}
          style={{ padding: "6px 10px", border: "1px solid #ddd", borderRadius: 8, textDecoration: "none" }}
        >
          {showHistory ? "Show open only" : "Show history"}
        </a>
      </div>

      <div style={{ border: "1px solid #ddd", padding: 12, borderRadius: 8 }}>
        <div style={{ fontWeight: 700, marginBottom: 8 }}>
          {showHistory ? "All Invites" : "Open Invites"}
        </div>

        {invErr && <div style={{ color: "crimson" }}>Select error: {invErr.message}</div>}

        {!invites?.length ? (
          <div>{showHistory ? "No invites." : "No open invites."}</div>
        ) : (
          <div style={{ display: "grid", gap: 8 }}>
            {invites.map((i: any) => {
              const isOpen = !i.accepted_at && !i.revoked_at;
              return (
                <div key={i.id} style={{ border: "1px solid #eee", padding: 10, borderRadius: 8, display: "grid", gap: 6 }}>
                  <div><b>Email:</b> {i.invited_email}</div>
                  <div><b>Role:</b> {i.invited_role}</div>
                  <div><b>Created:</b> {i.created_at}</div>
                  <div><b>Expires:</b> {i.expires_at}</div>
                  <div><b>Accepted:</b> {i.accepted_at ?? "-"}</div>
                  <div><b>Revoked:</b> {i.revoked_at ?? "-"}</div>

                  {isOpen ? <RevokeButton inviteId={i.id} /> : null}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

