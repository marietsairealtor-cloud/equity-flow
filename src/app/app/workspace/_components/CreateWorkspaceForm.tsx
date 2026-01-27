"use client";

import { useState } from "react";
import { supabaseBrowser } from "@/lib/supabase/client";

export default function CreateWorkspaceForm() {
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);

    const trimmed = name.trim();
    if (!trimmed) {
      setErr("Workspace name is required.");
      return;
    }

    setBusy(true);
    try {
      const supabase = supabaseBrowser();
      const { error } = await supabase.rpc("create_workspace", {
        p_workspace_name: trimmed,
      });
      if (error) throw error;

      window.location.href = "/app/gate";
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} style={{ display: "grid", gap: 8, maxWidth: 480 }}>
      <label style={{ fontWeight: 600 }}>Create workspace</label>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Workspace name"
        disabled={busy}
        style={{ padding: 10, border: "1px solid #ccc", borderRadius: 8 }}
      />
      <button
        type="submit"
        disabled={busy}
        style={{ padding: 10, border: "1px solid #ccc", borderRadius: 8, cursor: "pointer" }}
      >
        {busy ? "Creating..." : "Create workspace"}
      </button>
      {err ? <pre style={{ whiteSpace: "pre-wrap", color: "crimson" }}>{err}</pre> : null}
    </form>
  );
}
