"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { useSearchParams } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";

type Preview = {
  tenant_id: string;
  workspace_name: string;
  invited_email: string;
  invited_role: string;
  inviter_email: string | null;
  created_at: string;
  expires_at: string | null;
  status: string;
};

export default function AcceptInviteClient() {
  const sp = useSearchParams();
  const [token, setToken] = useState(sp.get("token") ?? "");
  const [preview, setPreview] = useState<Preview | null>(null);
  const [err, setErr] = useState("");
  const [isPending, startTransition] = useTransition();

  const supabase = useMemo(
    () =>
      createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      ),
    []
  );

  async function loadPreview(t: string) {
    setErr("");
    setPreview(null);
    const tt = t.trim();
    if (!tt) return;

    const { data, error } = await supabase.rpc("get_invite_preview_rpc", { token: tt });
    if (error) return setErr(error.message);

    const row = Array.isArray(data) && data.length > 0 ? (data[0] as any) : null;
    if (!row) return setErr("Invite not found");
    setPreview(row as Preview);
  }

  useEffect(() => {
    if (token) loadPreview(token);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function accept() {
    const t = token.trim();
    if (!t) return alert("token required");

    startTransition(async () => {
      setErr("");
      const { error } = await supabase.rpc("accept_invite_rpc", { token: t });
      if (error) return setErr(error.message);
      window.location.href = "/app/gate";
    });
  }

  return (
    <div style={{ padding: 20, background: "#0b0f19", color: "white", minHeight: "100vh" }}>
      <div style={{ maxWidth: 640, margin: "0 auto" }}>
        <div style={{ fontSize: 22, fontWeight: 900, marginBottom: 6 }}>Accept invite</div>

        <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginBottom: 12 }}>
          <input
            value={token}
            onChange={(e) => setToken(e.target.value)}
            placeholder="invite token (or open invite link)"
            style={{
              flex: "1 1 320px",
              padding: 12,
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(255,255,255,0.06)",
              color: "white",
            }}
          />
          <button
            onClick={() => loadPreview(token)}
            disabled={isPending}
            style={{
              padding: "12px 14px",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(0,0,0,0.15)",
              color: "white",
              cursor: "pointer",
            }}
          >
            Load
          </button>
        </div>

        {err ? (
          <div style={{ marginBottom: 12, padding: 12, borderRadius: 12, background: "rgba(180,0,0,0.18)", border: "1px solid rgba(255,80,80,0.35)" }}>
            <b>Error:</b> {err}
          </div>
        ) : null}

        {preview ? (
          <div style={{ padding: 12, borderRadius: 12, border: "1px solid rgba(255,255,255,0.12)", background: "rgba(255,255,255,0.06)", marginBottom: 12 }}>
            <div style={{ fontWeight: 900 }}>{preview.workspace_name}</div>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
              invited by: <b>{preview.inviter_email ?? "unknown"}</b>
            </div>
            <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
              role: {preview.invited_role} | status: {preview.status}
            </div>
            {preview.expires_at ? (
              <div style={{ fontSize: 12, opacity: 0.75, marginTop: 4 }}>expires: {String(preview.expires_at)}</div>
            ) : null}
          </div>
        ) : null}

        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <button
            onClick={accept}
            disabled={isPending || (preview?.status && preview.status !== "open")}
            style={{
              padding: "12px 14px",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(0,0,0,0.25)",
              color: "white",
              cursor: "pointer",
              fontWeight: 800,
              opacity: preview?.status && preview.status !== "open" ? 0.6 : 1,
            }}
            title={preview?.status && preview.status !== "open" ? "Invite is not open" : "Accept"}
          >
            Accept
          </button>

          <button
            onClick={() => (window.location.href = "/app/workspace")}
            disabled={isPending}
            style={{
              padding: "12px 14px",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(0,0,0,0.15)",
              color: "white",
              cursor: "pointer",
            }}
          >
            Back
          </button>
        </div>
      </div>
    </div>
  );
}