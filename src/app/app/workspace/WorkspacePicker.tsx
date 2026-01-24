"use client";

import { useState } from "react";

type Item = {
  tenant_id: string;
  workspace_name?: string | null;
  role: string;
};

export default function WorkspacePicker({ items }: { items?: Item[] }) {
  const [busy, setBusy] = useState(false);

  const safeItems = Array.isArray(items) ? items : [];

  // Deduplicate by tenant_id (prevents React key collisions)
  const seen = new Set<string>();
  const deduped = safeItems.filter((m) => {
    if (!m?.tenant_id) return false;
    if (seen.has(m.tenant_id)) return false;
    seen.add(m.tenant_id);
    return true;
  });

  async function selectTenant(tenantId: string) {
    setBusy(true);
    try {
      await fetch("/api/current-tenant", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tenant_id: tenantId }),
      });
      location.reload();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ display: "grid", gap: 12 }}>
      <div style={{ fontWeight: 900, fontSize: 18 }}>Workspace</div>

      {!deduped.length ? (
        <div>No workspaces.</div>
      ) : (
        <ul style={{ display: "grid", gap: 8, margin: 0, paddingLeft: 18 }}>
          {deduped.map((m) => (
            <li key={`${m.tenant_id}-${m.role}`}>
              <button disabled={busy} onClick={() => selectTenant(m.tenant_id)}>
                Select
              </button>{" "}
              <span style={{ fontFamily: "monospace" }}>
                {(m.workspace_name ?? "Workspace") + " (" + m.role + ")"} — {m.tenant_id}
              </span>
            </li>
          ))}
        </ul>
      )}

      <div style={{ border: "1px solid #ddd", borderRadius: 10, padding: 12, display: "grid", gap: 8 }}>
        <div style={{ fontWeight: 800 }}>Workspace tools</div>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
          <a href="/app/invites">Invites</a>
          <a href="/app/invite">Accept Invite</a>
          <a href="/app/members">Members</a>
        </div>
      </div>
    </div>
  );
}
