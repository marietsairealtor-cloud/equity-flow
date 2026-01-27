"use client";

import { useState } from "react";

export default function WorkspaceRowActions(props: { tenantId: string }) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function selectTenant() {
    setErr(null);
    setBusy(true);
    try {
      const res = await fetch("/api/workspace/select", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tenant_id: props.tenantId }),
      });
      if (!res.ok) {
        const txt = await res.text();
        throw new Error(txt || `HTTP ${res.status}`);
      }
      window.location.href = "/app/gate";
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>
      <button
        onClick={selectTenant}
        disabled={busy}
        style={{ padding: "8px 10px", border: "1px solid #ccc", borderRadius: 8, cursor: "pointer" }}
      >
        {busy ? "Selecting..." : "Select"}
      </button>

      <a href="/app/members" style={{ textDecoration: "underline" }}>Members</a>
      <a href="/app/invites" style={{ textDecoration: "underline" }}>Invites</a>

      {err ? <span style={{ color: "crimson", whiteSpace: "pre-wrap" }}>{err}</span> : null}
    </div>
  );
}
