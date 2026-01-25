"use client";

import { useState } from "react";
import { upgradeAndSave } from "./actions";

export default function UpgradeForm() {
  const [workspaceName, setWorkspaceName] = useState("");

  return (
    <form action={upgradeAndSave} style={{ display: "grid", gap: 12, maxWidth: 520 }}>
      <label style={{ display: "grid", gap: 6 }}>
        <span style={{ fontWeight: 600 }}>Workspace name</span>
        <input
          name="workspace_name"
          value={workspaceName}
          onChange={(e) => setWorkspaceName(e.target.value)}
          placeholder="My Company"
          style={{
            padding: "10px 12px",
            border: "1px solid #ccc",
            borderRadius: 8,
            color: "#111",
            background: "#fff",
          }}
        />
      </label>

      <input type="hidden" name="idempotency_key" value={"W3-" + crypto.randomUUID()} />

      <button
        type="submit"
        style={{
          padding: "10px 12px",
          border: "1px solid #111",
          borderRadius: 8,
          background: "#111",
          color: "#fff",
          fontWeight: 600,
          cursor: "pointer",
        }}
      >
        Upgrade & Save
      </button>

      <p style={{ margin: 0, fontSize: 12, color: "#444" }}>
        This will provision your workspace (if needed), seed your first deal once (idempotent), select the workspace, and
        open the deal.
      </p>
    </form>
  );
}