"use client";

import { useState } from "react";

export default function RevokeButton({ inviteId }: { inviteId: string }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function revoke() {
    setLoading(true);
    setError(null);

    const res = await fetch("/api/invites/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ invite_id: inviteId }),
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
      <button onClick={revoke} disabled={loading} style={{ padding: "6px 10px" }}>
        {loading ? "Revoking..." : "Revoke"}
      </button>
      {error && <div style={{ color: "crimson" }}>{error}</div>}
    </div>
  );
}
