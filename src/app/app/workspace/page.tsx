import Link from "next/link";
import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

export default async function WorkspacePage({ searchParams }: any) {
  const supabase = await supabaseServer();

  const { data: userRes } = await supabase.auth.getUser();
  const user = userRes?.user;
  if (!user) redirect("/login");

  const { data: ents } = await supabase.rpc("get_entitlements");
  const ent = Array.isArray(ents) ? ents[0] : null;

  // Try RPC first (preferred)
  let list: any[] = [];
  const { data: wsRpc, error: wsRpcErr } = await supabase.rpc("get_my_workspaces_rpc");

  if (!wsRpcErr && Array.isArray(wsRpc)) {
    list = wsRpc;
  } else {
    // Fallback: direct SELECT (reads only) to unblock you when schema cache is acting up
    const { data: rows, error: selErr } = await supabase
      .from("tenant_memberships")
      .select(`
        tenant_id,
        role,
        tenants:tenants (
          id,
          workspace_name,
          subscription_status,
          subscription_tier,
          trial_ends_at,
          seat_limit,
          seat_count
        )
      `)
      .eq("user_id", user.id)
      .order("created_at", { ascending: false });

    if (selErr) {
      // show the original RPC error if that's what happened, otherwise show select error
      const msg = wsRpcErr?.message || selErr.message;
      return (
        <div style={{ padding: 16 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h1>Workspaces</h1>
            <form method="post" action="/auth/logout"><button type="submit">Logout</button></form>
          </div>
          <div style={{ color: "crimson" }}>Error: {msg}</div>
        </div>
      );
    }

    list = (rows ?? []).map((r: any) => ({
      tenant_id: r.tenant_id,
      workspace_name: r.tenants?.workspace_name,
      role: r.role,
      tier: r.tenants?.subscription_tier,
      status: r.tenants?.subscription_status,
      trial_ends_at: r.tenants?.trial_ends_at,
      seat_limit: r.tenants?.seat_limit,
      seat_count: r.tenants?.seat_count,
    }));
  }

  const err = String(searchParams?.err ?? "");

  return (
    <div style={{ padding: 16 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1>Workspaces</h1>
        <form method="post" action="/auth/logout"><button type="submit">Logout</button></form>
      </div>

      {err && <div style={{ color: "crimson", marginBottom: 12 }}>Error: {err}</div>}

      <div style={{ marginBottom: 12 }}>
        <div><b>Current tenant:</b> {String(ent?.tenant_id ?? "")}</div>
        <div><b>Current workspace:</b> {String(ent?.workspace_name ?? "")}</div>
      </div>

      {list.length === 0 ? (
        <div>No workspaces found for this account.</div>
      ) : (
        <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
          {list.map((w: any) => (
            <li key={w.tenant_id} style={{ padding: 10, border: "1px solid #eee", borderRadius: 8, marginBottom: 10 }}>
              <div style={{ fontWeight: 600 }}>{w.workspace_name}</div>
              <div>tenant: <span style={{ fontFamily: "monospace" }}>{w.tenant_id}</span></div>
              <div>role: {w.role} | status: {w.status} | tier: {w.tier}</div>
              <div>seats: {w.seat_count} / {w.seat_limit}</div>

              <form method="post" action="/app/workspace/select" style={{ marginTop: 8 }}>
                <input type="hidden" name="tenant_id" value={w.tenant_id} />
                <button type="submit">Select this workspace</button>
              </form>
            </li>
          ))}
        </ul>
      )}

      <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
        <Link href="/app/invites">Invites</Link>
        <Link href="/app/members">Members</Link>
        <Link href="/app/deals">Deals</Link>
        <Link href="/app/home">Home</Link>
      </div>
    </div>
  );
}