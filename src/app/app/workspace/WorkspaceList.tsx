"use client";

import { useMemo, useState, useTransition } from "react";
import { createBrowserClient } from "@supabase/ssr";

type Workspace = {
  tenant_id: string;
  workspace_name: string;
  role: string;
  tier: string;
  status: string;
  trial_ends_at: string | null;
  seat_limit: number;
  seat_count: number;
};

export default function WorkspaceList({ workspaces }: { workspaces: Workspace[] }) {
  const [isPending, startTransition] = useTransition();
  const [openId, setOpenId] = useState<string | null>(null);
  const [membersByTenant, setMembersByTenant] = useState<Record<string, any[]>>({});
  const [loadingMembers, setLoadingMembers] = useState<Record<string, boolean>>({});

  const supabase = useMemo(
    () =>
      createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      ),
    []
  );

  async function selectTenant(tenant_id: string) {
    const { error } = await supabase.rpc("set_current_tenant", { p_tenant_id: tenant_id });
    if (error) throw new Error(error.message);
  }

  async function selectTenantAndGo(tenant_id: string, path: string) {
    startTransition(async () => {
      try {
        await selectTenant(tenant_id);
        window.location.href = path;
      } catch (e: any) {
        alert(e.message ?? String(e));
      }
    });
  }

  async function toggleMembers(tenant_id: string) {
    const next = openId === tenant_id ? null : tenant_id;
    setOpenId(next);

    if (!next) return;
    if (membersByTenant[next]) return;

    setLoadingMembers((s) => ({ ...s, [next]: true }));
    const { data, error } = await supabase.rpc("get_tenant_members", { p_tenant_id: next });
    setLoadingMembers((s) => ({ ...s, [next]: false }));
    if (error) return alert(error.message);

    setMembersByTenant((s) => ({ ...s, [next]: data ?? [] }));
  }

  async function leaveWorkspace(tenant_id: string) {
    if (!confirm("Leave this workspace?")) return;
    startTransition(async () => {
      const { error } = await supabase.rpc("leave_workspace", { p_tenant_id: tenant_id });
      if (error) return alert(error.message);
      window.location.reload();
    });
  }

  async function deleteWorkspace(tenant_id: string, name: string) {
    const ok = confirm(`Delete workspace "${name}"?\nThis is permanent.`);
    if (!ok) return;

    startTransition(async () => {
      try {
        await selectTenant(tenant_id); // set CURRENT tenant first
        const { error } = await supabase.rpc("delete_current_workspace_rpc");
        if (error) return alert(error.message);
        window.location.href = "/app/workspace";
      } catch (e: any) {
        alert(e.message ?? String(e));
      }
    });
  }

  const btn = (style: any) => ({
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid rgba(255,255,255,0.18)",
    background: "rgba(0,0,0,0.15)",
    color: "white",
    cursor: "pointer",
    ...style,
  });

  return (
    <div style={{ display: "grid", gap: 12 }}>
      {workspaces.map((w) => {
        const isOpen = openId === w.tenant_id;
        const members = membersByTenant[w.tenant_id] ?? [];
        const isOwner = (w.role || "").toLowerCase() === "owner";

        return (
          <div
            key={w.tenant_id}
            style={{
              borderRadius: 14,
              border: "1px solid rgba(255,255,255,0.12)",
              background: "rgba(255,255,255,0.06)",
              color: "white",
              padding: 14,
            }}
          >
            <div
              style={{
                display: "flex",
                gap: 10,
                justifyContent: "space-between",
                alignItems: "flex-start",
                flexWrap: "wrap",
              }}
            >
              <div style={{ minWidth: 260 }}>
                <div style={{ fontWeight: 900, fontSize: 16 }}>{w.workspace_name}</div>
                <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
                  role: {w.role} | tier: {w.tier} | status: {w.status}
                </div>
                <div style={{ fontSize: 12, opacity: 0.75, marginTop: 4 }}>
                  seats: {w.seat_count} / {w.seat_limit}
                </div>
              </div>

              <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
                <button onClick={() => selectTenantAndGo(w.tenant_id, "/app/gate")} disabled={isPending} style={btn({ background: "rgba(0,0,0,0.25)", fontWeight: 800 })}>
                  Use
                </button>

                <button onClick={() => toggleMembers(w.tenant_id)} disabled={isPending} style={btn({})}>
                  {isOpen ? "Hide members" : "Show members"}
                </button>

                <button onClick={() => selectTenantAndGo(w.tenant_id, "/app/invites")} disabled={isPending} style={btn({})}>
                  Invites
                </button>

                <button onClick={() => (window.location.href = "/app/accept-invite")} disabled={isPending} style={btn({})}>
                  Accept invite
                </button>

                <button
                  onClick={() => leaveWorkspace(w.tenant_id)}
                  disabled={isPending || isOwner}
                  title={isOwner ? "Owner cannot leave (delete workspace instead)" : "Leave workspace"}
                  style={btn({
                    background: isOwner ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.15)",
                    cursor: isOwner ? "not-allowed" : "pointer",
                    opacity: isOwner ? 0.6 : 1,
                  })}
                >
                  Leave
                </button>

                <button
                  onClick={() => deleteWorkspace(w.tenant_id, w.workspace_name)}
                  disabled={isPending || !isOwner}
                  title={!isOwner ? "Owner only" : "Delete workspace"}
                  style={btn({
                    background: !isOwner ? "rgba(255,255,255,0.08)" : "rgba(180,0,0,0.35)",
                    cursor: !isOwner ? "not-allowed" : "pointer",
                    opacity: !isOwner ? 0.6 : 1,
                    fontWeight: 800,
                  })}
                >
                  Delete
                </button>
              </div>
            </div>

            {isOpen ? (
              <div style={{ marginTop: 12, paddingTop: 12, borderTop: "1px solid rgba(255,255,255,0.10)" }}>
                <div style={{ fontWeight: 900, marginBottom: 8 }}>Members</div>
                {loadingMembers[w.tenant_id] ? (
                  <div style={{ opacity: 0.85 }}>Loadingâ€¦</div>
                ) : members.length === 0 ? (
                  <div style={{ opacity: 0.85 }}>No members returned.</div>
                ) : (
                  <div style={{ display: "grid", gap: 8 }}>
                    {members.map((m: any, i: number) => (
                      <div
                        key={(m.user_id ?? i) + ":" + i}
                        style={{
                          padding: 10,
                          borderRadius: 12,
                          border: "1px solid rgba(255,255,255,0.10)",
                          background: "rgba(0,0,0,0.18)",
                        }}
                      >
                        <div style={{ fontWeight: 800 }}>{m.email ?? m.user_id}</div>
                        <div style={{ fontSize: 12, opacity: 0.85 }}>role: {m.role}</div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ) : null}
          </div>
        );
      })}
    </div>
  );
}