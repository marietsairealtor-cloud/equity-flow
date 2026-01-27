"use client";

import { useState } from "react";

export default function StatusClient(props: { dealId: string; rowVersion: number }) {
  const [msg, setMsg] = useState<string>("");

  async function setStatus(status: string) {
    setMsg("Saving...");

    const res = await fetch(`/app/deals/${props.dealId}/status`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        status,
        expected_row_version: props.rowVersion,
      }),
    });

    const txt = await res.text();
    if (!res.ok) {
      setMsg(txt || "ERROR");
      return;
    }

    setMsg("Saved. Refreshing...");
    window.location.reload();
  }

  return (
    <div>
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        {["New", "Contacted", "Offer Made", "Under Contract", "Closed", "Dead"].map((s) => (
          <button key={s} onClick={() => setStatus(s)}>
            {s}
          </button>
        ))}
      </div>

      <div style={{ marginTop: 8, whiteSpace: "pre-wrap" }}>{msg}</div>
    </div>
  );
}
