"use client";

import * as React from "react";
import { upgradeAndSave } from "./actions";

const initialState = { ok: false, error: "" };

function SubmitButton({ pending }: { pending: boolean }) {
  return (
    <button
      type="submit"
      disabled={pending}
      style={{
        padding: "10px 12px",
        borderRadius: 10,
        border: "1px solid #ddd",
        background: "white",
        cursor: pending ? "not-allowed" : "pointer",
      }}
    >
      {pending ? "Working..." : "Upgrade & Save (start trial)"}
    </button>
  );
}

export default function UpgradeForm(props: { defaultWorkspaceName?: string; status?: string }) {
  const [state, formAction, pending] = React.useActionState(upgradeAndSave as any, initialState as any);

  return (
    <div style={{ maxWidth: 720, padding: 16 }}>
      <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 6 }}>Upgrade & Save</h1>
      <div style={{ fontSize: 13, color: "#444", marginBottom: 12 }}>
        Status: <b>{props.status || "-"}</b>
      </div>

      <form action={formAction} style={{ display: "grid", gap: 12 }}>
        <label style={{ display: "grid", gap: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>Workspace name</div>
          <input
            name="workspace_name"
            defaultValue={props.defaultWorkspaceName ?? ""}
            placeholder="e.g. Marie Home Buyers"
            style={{ padding: "10px 12px", borderRadius: 10, border: "1px solid #ddd" }}
            autoComplete="organization"
          />
        </label>

        <label style={{ display: "grid", gap: 6 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>First deal JSON (optional)</div>
          <textarea
            name="first_deal_json"
            defaultValue={`{}`}
            rows={10}
            style={{
              padding: "10px 12px",
              borderRadius: 10,
              border: "1px solid #ddd",
              fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
              fontSize: 12,
            }}
          />
        </label>

        {state?.error ? (
          <div
            style={{
              padding: "10px 12px",
              borderRadius: 10,
              border: "1px solid #f0c2c2",
              background: "#fff7f7",
              fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
              fontSize: 12,
              whiteSpace: "pre-wrap",
            }}
          >
            {String(state.error)}
          </div>
        ) : null}

        <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
          <SubmitButton pending={pending} />
          <a href="/app/billing" style={{ fontSize: 13, color: "#444" }}>Back to Billing</a>
        </div>
      </form>
    </div>
  );
}

