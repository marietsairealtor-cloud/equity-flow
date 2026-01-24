"use client";

import { useState } from "react";
import { supabaseBrowser } from "@/lib/supabase-browser";

export default function CreateDealButton() {
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function create() {
    setErr(null);
    setBusy(true);

    const supabase = supabaseBrowser();

    const { error } = await supabase.from("deals").insert({
      status: "New",
    });

    setBusy(false);

    if (error) {
      setErr(error.message);
      return;
    }

    window.location.reload();
  }

  return (
    <div style={{ display: "grid", gap: 8 }}>
      <button onClick={create} disabled={busy}>
        {busy ? "Creating..." : "Create deal"}
      </button>
      {err && <p style={{ color: "crimson" }}>{err}</p>}
    </div>
  );
}
