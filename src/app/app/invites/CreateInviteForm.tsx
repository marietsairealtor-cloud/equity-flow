"use client";

import { useState } from "react";

export default function CreateInviteForm({ tenantId, workspaceName }: { tenantId: string; workspaceName: string }) {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("member");
  const [raw, setRaw] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setRaw(null);

    const res = await fetch("/api/invites/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ Workspace: tenantId, email, role }),
    });

    const json = await res.json().catch(() => ({}));
    setRaw({ status: res.status, ok: res.ok, json });
    setLoading(false);
  }

  const token = raw?.json?.invite?.token;

  return (
    <div style={{ border: "1px solid #ddd", padding: 12, borderRadius: 8 }}>
      <div style={{ fontWeight: 700, marginBottom: 8 }}>Create Invite</div>

      <div style={{ marginBottom: 8, fontFamily: "monospace" }}>
        tenantId: {workspaceName}
      </div>

      <form onSubmit={onSubmit} style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
        <input
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="email@example.com"
          style={{ padding: 8, minWidth: 240 }}
          required
        />

        <select value={role} onChange={(e) => setRole(e.target.value)} style={{ padding: 8 }}>
          <option value="member">member</option>
          <option value="admin">admin</option>
        </select>

        <button type="submit" disabled={loading} style={{ padding: "8px 12px" }}>
          {loading ? "Creating..." : "Create"}
        </button>
      </form>

      <div style={{ marginTop: 12, padding: 10, border: "1px solid #eee", borderRadius: 8 }}>
        <div style={{ fontWeight: 700, marginBottom: 6 }}>INVITE TOKEN (if ok)</div>
        <div style={{ fontFamily: "monospace", wordBreak: "break-all" }}>
          {token ?? "-"}
        </div>
      </div>

      <div style={{ marginTop: 12 }}>
        <div style={{ fontWeight: 700, marginBottom: 6 }}>Raw response</div>
        <pre style={{ background: "#f7f7f7", padding: 10, borderRadius: 8, overflowX: "auto" }}>
{JSON.stringify(raw, null, 2)}
        </pre>
      </div>
    </div>
  );
}

