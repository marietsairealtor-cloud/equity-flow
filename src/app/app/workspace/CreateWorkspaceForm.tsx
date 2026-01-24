"use client";

import { useState } from "react";
import { supabaseBrowser } from "@/lib/supabase-browser";

export default function CreateWorkspaceForm() {
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setBusy(true);

    const supabase = supabaseBrowser();
    const { error } = await supabase.rpc("create_workspace", { p_workspace_name: name });

    setBusy(false);

    if (error) {
      setErr(error.message);
      return;
    }

    window.location.href = "/app";
  }

  return (
    <form onSubmit={onSubmit} style={{ display: "grid", gap: 12, maxWidth: 420 }}>
      <label style={{ display: "grid", gap: 6 }}>
        <span>Workspace name</span>
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>

      <button type="submit" disabled={busy}>
        {busy ? "Creating..." : "Create workspace"}
      </button>

      {err && <p style={{ color: "crimson" }}>{err}</p>}
    </form>
  );
}
