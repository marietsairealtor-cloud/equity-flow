import Link from "next/link";
import CreateWorkspaceForm from "./_components/CreateWorkspaceForm";
import WorkspaceRowActions from "./_components/WorkspaceRowActions";
import { supabaseServer } from "@/lib/supabase/server";

export default async function WorkspacePage() {
  const supabase = await supabaseServer();

  const { data: me } = await supabase.auth.getUser();
  const { data: entitlements } = await supabase.rpc("get_entitlements");

  const { data: memberships, error: mErr } = await supabase
    .from("tenant_memberships")
    .select("tenant_id, role, created_at, tenants(workspace_name, subscription_status, subscription_tier)")
    .order("created_at", { ascending: false });

  return (
    <div style={{ padding: 24, display: "grid", gap: 16 }}>
      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <h1 style={{ margin: 0 }}>Workspace</h1>
        <Link href="/app/gate">Go to Gate</Link>        <Link href="/auth/logout">Logout</Link>
      </div>

      <div style={{ border: "1px solid #ddd", borderRadius: 12, padding: 16 }}>
        <div style={{ fontWeight: 600, marginBottom: 8 }}>State probe</div>
        <pre style={{ whiteSpace: "pre-wrap" }}>
{JSON.stringify(
  {
    me: { email: me?.user?.email ?? null, userId: me?.user?.id ?? null },
    entitlements: entitlements ?? null,
    memberships_error: mErr?.message ?? null,
  },
  null,
  2
)}
        </pre>
      </div>

      <div style={{ border: "1px solid #ddd", borderRadius: 12, padding: 16 }}>
        <CreateWorkspaceForm />
      </div>

      <div style={{ border: "1px solid #ddd", borderRadius: 12, padding: 16 }}>
        <div style={{ fontWeight: 600, marginBottom: 8 }}>Join workspace</div>
        <div style={{ display: "grid", gap: 8, maxWidth: 480 }}>
          <div>Accept an invite to join an existing workspace.</div>
          <Link href="/app/accept-invite">Accept invite</Link>
        </div>
      </div>

      <div style={{ border: "1px solid #ddd", borderRadius: 12, padding: 16 }}>
        <div style={{ fontWeight: 600, marginBottom: 8 }}>Your memberships</div>
        {memberships && memberships.length ? (
          <ul style={{ margin: 0, paddingLeft: 18 }}>
            {memberships.map((m: any) => (
              <li key={`${m.tenant_id}-${m.created_at}`} style={{ marginBottom: 6 }}>
                <span style={{ fontFamily: "monospace" }}>{m.tenant_id}</span>{" "}
                | {m?.tenants?.workspace_name ?? "(no name)"} | {m.role} |{" "}
                {m?.tenants?.subscription_tier ?? "?"} | {m?.tenants?.subscription_status ?? "?"}
                              <WorkspaceRowActions tenantId={m.tenant_id} />
              </li>
            ))}
          </ul>
        ) : (
          <div>No memberships found.</div>
        )}
      </div>
    </div>
  );
}



