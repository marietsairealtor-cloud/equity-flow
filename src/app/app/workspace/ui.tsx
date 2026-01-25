"use client";

import { useState } from "react";

type Ws = {
  tenant_id: string;
  workspace_name: string | null;
  role: string;
  tier: string;
  status: string;
  trial_ends_at: string | null;
};

const UI = {
  page: { padding: 16, maxWidth: 900, color: "#eee" as const },
  h1: { fontSize: 20, fontWeight: 800, color: "#fff" as const, margin: 0 },
  card: { padding: "12px 12px", borderRadius: 12, border: "1px solid #2a2a2a", background: "#0f0f0f" as const },
  subtle: { fontSize: 13, color: "#bbb" as const },
  btn: {
    padding: "8px 10px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#1a1a1a",
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

export default function WorkspaceUI(props: { workspaces: Ws[]; serverError?: string | null }) {
  const [busy, setBusy] = useState("");
  const [err, setErr] = useState("");

  async function selectWs(tenant_id: string) {
    setErr("");
    setBusy(tenant_id);
    try {
      const res = await fetch("/api/workspace/select", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tenant_id }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "SELECT_FAILED");
      window.location.href = "/app/gate";
    } catch (e: any) {
      setErr(e?.message ?? "SELECT_FAILED");
      setBusy("");
    }
  }

  return (
    <div style={UI.page}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <h1 style={UI.h1}>Workspaces</h1>
        <a href="/app/home" style={{ fontSize: 13, color: "#9cc9ff", textDecoration: "none" }}>Home</a>
      </div>

      {props.serverError ? <div style={UI.err}>SERVER: {props.serverError}</div> : null}{err ? <div style={UI.err}>{err}</div> : null}

      <div style={{ marginTop: 12, display: "grid", gap: 8 }}>
        {!props.workspaces?.length ? (
          <div style={UI.subtle}>No workspaces found for this user.</div>
        ) : (
          props.workspaces.map((w) => (
            <div key={w.tenant_id} style={UI.card}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "#fff" }}>{w.workspace_name ?? w.tenant_id}</div>
                  <div style={UI.subtle}>
                    {w.role} â€¢ {w.tier} â€¢ {w.status} {w.trial_ends_at ? `â€¢ trial ends ${w.trial_ends_at}` : ""}
                  </div>
                </div>
                <button style={UI.btn} disabled={busy === w.tenant_id} onClick={() => selectWs(w.tenant_id)}>
                  {busy === w.tenant_id ? "..." : "Select"}
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}