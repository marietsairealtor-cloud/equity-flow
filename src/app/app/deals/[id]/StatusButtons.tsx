"use client";

import { useState } from "react";

export default function StatusButtons({ id }: { id: string }) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function setStatus(status: string) {
    setErr(null);
    setBusy(true);

    const res = await fetch(`/app/deals/${id}/status`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ status }),
    });

    setBusy(false);

    if (!res.ok) {
      const j = await res.json().catch(() => ({}));
      setErr(j.error || "Update failed");
      return;
    }

    window.location.reload();
  }

  return (
    <div style={{ display: "grid", gap: 8, maxWidth: 520 }}>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <button disabled={busy} onClick={() => setStatus("New")}>New</button>
        <button disabled={busy} onClick={() => setStatus("Contacted")}>Contacted</button>
        <button disabled={busy} onClick={() => setStatus("Qualified")}>Qualified</button>
        <button disabled={busy} onClick={() => setStatus("Closed")}>Closed</button>
      </div>
      {err && <p style={{ color: "crimson" }}>{err}</p>}
    </div>
  );
}
