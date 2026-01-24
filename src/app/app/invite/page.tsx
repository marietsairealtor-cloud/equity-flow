"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function AcceptInvitePage() {
  const router = useRouter();
  const [token, setToken] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [raw, setRaw] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setRaw(null);

    const res = await fetch("/api/invites/accept", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
    });

    const json = await res.json().catch(() => ({}));
    setRaw({ status: res.status, ok: res.ok, json });
    setLoading(false);

    if (!res.ok) {
      setError(json?.error ?? "Failed");
      return;
    }

    router.replace("/app/home");
  }

  return (
    <div style={{ padding: 16, display: "grid", gap: 12, maxWidth: 760 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>Accept Invite</div>

      <form onSubmit={onSubmit} style={{ display: "grid", gap: 8 }}>
        <input
          value={token}
          onChange={(e) => setToken(e.target.value)}
          placeholder="paste invite token"
          style={{ padding: 10, fontFamily: "monospace" }}
          required
        />
        <button type="submit" disabled={loading} style={{ padding: "10px 12px" }}>
          {loading ? "Accepting..." : "Accept"}
        </button>
      </form>

      {error && <div style={{ color: "crimson" }}>{error}</div>}

      <div>
        <div style={{ fontWeight: 800, marginBottom: 6 }}>Raw response</div>
        <pre style={{ background: "#f7f7f7", padding: 10, borderRadius: 8, overflowX: "auto" }}>
{JSON.stringify(raw, null, 2)}
        </pre>
      </div>
    </div>
  );
}
