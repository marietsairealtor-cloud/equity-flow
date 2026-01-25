"use client";

import { useState } from "react";

const OPTIONS: { value: string; label: string }[] = [
  { value: "New", label: "New" },
  { value: "Contacted", label: "Contacted" },
  { value: "Qualified", label: "Qualified" },
  { value: "Appointment Set", label: "Appointment Set" },
  { value: "Offer Made", label: "Offer Made" },
  { value: "Under Contract", label: "Under Contract" },
  { value: "Closed", label: "Closed" },
  { value: "Closed/Assigned", label: "Closed/Assigned (legacy)" },
  { value: "Dead", label: "Dead" },
];

export default function StatusClient(props: { dealId: string; status: string }) {
  const [status, setStatus] = useState(props.status);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function save(next: string) {
    setErr("");
    setBusy(true);
    try {
      const res = await fetch(`/app/deals/${props.dealId}/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: next }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "STATUS_UPDATE_FAILED");
      setStatus(next);
    } catch (e: any) {
      setErr(e?.message ?? "STATUS_UPDATE_FAILED");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ display: "grid", gap: 8 }}>
      <div style={{ fontSize: 13, color: "#bbb" }}>Status</div>

      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
        <select
          value={status}
          disabled={busy}
          onChange={(e) => save(e.target.value)}
          style={{
            padding: "6px 8px",
            borderRadius: 10,
            border: "1px solid #3a3a3a",
            background: "#121212",
            color: "#eee",
          }}
        >
          {OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>

        {busy ? <div style={{ fontSize: 13, color: "#bbb" }}>Savingâ€¦</div> : null}
      </div>

      {err ? (
        <div style={{ padding: "10px 12px", borderRadius: 10, border: "1px solid #7a2a2a", background: "#1a0f0f", color: "#ffd0d0", fontSize: 12, whiteSpace: "pre-wrap" }}>
          {err}
        </div>
      ) : null}
    </div>
  );
}