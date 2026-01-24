import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";
import RemoveButton from "./RemoveButton";

export default async function MembersPage() {
  const supabase = await createSupabaseServerClient();

  const { data: ent, error: entErr } = await supabase.rpc("get_entitlements");
  if (entErr) redirect("/login");

  const entRow = Array.isArray(ent) ? ent[0] : (ent as any);
  const workspaceName = (entRow as any)?.workspace_name ?? "-";
  const tenantId = entRow?.tenant_id as string | undefined;
  const myRole = entRow?.role as string | undefined;

  if (!tenantId) redirect("/app/workspace");

  const { data: members, error: memErr } = await supabase.rpc("get_tenant_members", {
    p_Workspace: tenantId,
  });

  const canManage = myRole === "owner" || myRole === "admin";

  return (
    <div style={{ padding: 16, display: "grid", gap: 16 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>Members</div>

      {memErr && <div style={{ color: "crimson" }}>Select error: {memErr.message}</div>}

      {!members?.length ? (
        <div>No members.</div>
      ) : (
        <div style={{ display: "grid", gap: 8 }}>
          {(members as any[]).map((m) => (
            <div
              key={m.user_id}
              style={{
                border: "1px solid #eee",
                padding: 10,
                borderRadius: 8,
                display: "flex",
                justifyContent: "space-between",
                gap: 12,
              }}
            >
              <div>
                <div><b>Email:</b> {m.email ?? "-"}</div>
                <div><b>User:</b> {m.user_id}</div>
                <div><b>Role:</b> {m.role}</div>
                <div><b>Joined:</b> {m.created_at}</div>
              </div>

              {canManage && m.role !== "owner" ? (
                <RemoveButton tenantId={workspaceName} userId={m.user_id} />
              ) : null}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
