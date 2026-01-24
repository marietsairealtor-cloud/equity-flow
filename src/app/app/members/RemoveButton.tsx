"use client";

import { useState } from "react";

export default function RemoveButton({ tenantId, userId }: { tenantId: string; userId: string }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function remove() {
    setLoading(true);
    setError(null);

    const res = await fetch("/api/members/remove", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ Workspace: tenantId, user_id: userId }),
    });

    const json = await res.json().catch(() => ({}));
    setLoading(false);

    if (!res.ok) {
      setError(json?.error ?? "Failed");
      return;
    }

    location.reload();
  }

  return (
    <div style={{ display: "inline-flex", flexDirection: "column", gap: 6 }}>
      <button onClick={remove} disabled={loading} style={{ padding: "6px 10px" }}>
        {loading ? "Removing..." : "Remove"}
      </button>
      {error && <div style={{ color: "crimson" }}>{error}</div>}
    </div>
  );
}
