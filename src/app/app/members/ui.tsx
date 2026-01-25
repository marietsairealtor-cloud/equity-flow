"use client";

import { useMemo, useState } from "react";

type MemberRow = {
  user_id: string;
  email: string | null;
  role: string;
};

const UI = {
  page: { padding: 16, maxWidth: 900, color: "#eee" as const },
  card: { padding: "12px 12px", borderRadius: 12, border: "1px solid #2a2a2a", background: "#0f0f0f" as const },
  h1: { fontSize: 20, fontWeight: 800, color: "#fff" as const, margin: 0 },
  subtle: { fontSize: 13, color: "#bbb" as const },
  btn: {
    padding: "8px 10px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#1a1a1a",
    color: "#eee",
  } as const,
  sel: {
    padding: "6px 8px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#121212",
    color: "#eee",
  } as const,
  err: {
    marginTop: 10,
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid #7a2a2a",
    background: "#1a0f0f",
    color: "#ffd0d0",
    fontSize: 12,
    whiteSpace: "pre-wrap" as const,
  },
};

export default function MembersUI(props: {
  tenantId: string | null;
  workspaceName: string | null;
  initialMembers: MemberRow[];
}) {
  const [members, setMembers] = useState<MemberRow[]>(props.initialMembers ?? []);
  const [busyId, setBusyId] = useState<string>("");
  const [err, setErr] = useState("");

  const canAct = useMemo(() => !!props.tenantId, [props.tenantId]);

  async function refresh() {
    window.location.reload();
  }

  async function setRole(user_id: string, role: string) {
    setErr("");
    if (!props.tenantId) { setErr("NO_TENANT_SELECTED"); return; }
    setBusyId(user_id);
    try {
      const res = await fetch("/api/members/set-role", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tenant_id: props.tenantId, user_id, role }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "SET_ROLE_FAILED");
      await refresh();
    } catch (e: any) {
      setErr(e?.message ?? "SET_ROLE_FAILED");
      setBusyId("");
    }
  }

  async function remove(user_id: string) {
    setErr("");
    if (!props.tenantId) { setErr("NO_TENANT_SELECTED"); return; }
    setBusyId(user_id);
    try {
      const res = await fetch("/api/members/remove", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tenant_id: props.tenantId, user_id }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "REMOVE_FAILED");
      await refresh();
    } catch (e: any) {
      setErr(e?.message ?? "REMOVE_FAILED");
      setBusyId("");
    }
  }

  return (
    <div style={UI.page}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <h1 style={UI.h1}>Members</h1>
        <div style={UI.subtle}>{props.workspaceName ?? "-"}</div>
      </div>

      {err ? <div style={UI.err}>{err}</div> : null}

      <div style={{ marginTop: 12, display: "grid", gap: 8 }}>
        {!members?.length ? (
          <div style={UI.subtle}>No members.</div>
        ) : (
          members.map((m) => (
            <div key={m.user_id} style={UI.card}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "#fff" }}>{m.email ?? m.user_id}</div>
                  <div style={UI.subtle}>user_id: {m.user_id}</div>
                </div>

                <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  <select
                    value={m.role}
                    disabled={!canAct || busyId === m.user_id}
                    style={UI.sel}
                    onChange={(e) => setRole(m.user_id, e.target.value)}
                  >
                    <option value="owner">owner</option>
                    <option value="admin">admin</option>
                    <option value="member">member</option>
                  </select>

                  <button
                    style={UI.btn}
                    disabled={!canAct || busyId === m.user_id || m.role === "owner"}
                    onClick={() => remove(m.user_id)}
                    title={m.role === "owner" ? "Cannot remove owner" : "Remove"}
                  >
                    {busyId === m.user_id ? "..." : "Remove"}
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}