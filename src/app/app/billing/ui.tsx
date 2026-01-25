"use client";

import { useState } from "react";

export default function BillingClient(props: {
  status: string;
  tier: string;
  workspaceName: string;
  trialEndsAt: string | null;
}) {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  async function chooseCore() {
    setErr("");
    setBusy(true);
    try {
      const res = await fetch("/api/billing/choose-plan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tier: "core" }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "CHOOSE_PLAN_FAILED");
      window.location.href = "/app/gate";
    } catch (e: any) {
      setErr(e?.message ?? "CHOOSE_PLAN_FAILED");
      setBusy(false);
    }
  }

  return (
    <div style={{ padding: 16, maxWidth: 720 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>Billing</div>
      <div style={{ marginTop: 6, fontSize: 13, color: "#444" }}>
        Workspace: <b>{props.workspaceName || "-"}</b>
      </div>

      <div style={{ marginTop: 10, padding: "12px 12px", borderRadius: 12, border: "1px solid #eee" }}>
        <div style={{ fontSize: 13 }}>
          Status: <b>{props.status}</b> • Tier: <b>{props.tier}</b>
          {props.trialEndsAt ? (
            <span> • Trial ends: <b>{props.trialEndsAt}</b></span>
          ) : null}
        </div>

        <div style={{ marginTop: 12, display: "grid", gap: 10 }}>
          <div style={{ fontSize: 14 }}>
            Core plan starts a 14-day trial (writes enabled during trialing/active).
          </div>

          <button
            onClick={chooseCore}
            disabled={busy}
            style={{
              width: "fit-content",
              padding: "10px 12px",
              borderRadius: 10,
              border: "1px solid #ddd",
              background: "white",
              color: "black",
            }}
          >
            {busy ? "Starting..." : "Start Core Trial"}
          </button>

          {err ? (
            <div style={{ padding: "10px 12px", borderRadius: 10, border: "1px solid #f0c2c2", background: "#fff7f7", fontSize: 12, whiteSpace: "pre-wrap" }}>
              {err}
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}