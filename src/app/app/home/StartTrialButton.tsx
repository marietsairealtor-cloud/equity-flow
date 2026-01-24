"use client";

import { useState } from "react";

export default function StartTrialButton({ tenantId }: { tenantId: string }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function start() {
    setLoading(true);
    setError(null);

    const res = await fetch("/api/billing/start-trial", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tenant_id: tenantId, days: 14 }),
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
    <div style={{ display: "grid", gap: 6 }}>
      <button onClick={start} disabled={loading} style={{ padding: "8px 12px" }}>
        {loading ? "Starting..." : "Start 14-day trial"}
      </button>
      {error && <div style={{ color: "crimson" }}>{error}</div>}
    </div>
  );
}
