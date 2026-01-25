"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { createBrowserClient } from "@supabase/ssr";

type PendingInvite = {
  invite_id: string;
  tenant_id: string;
  workspace_name: string;
  invited_role: string;
  token: string;
  inviter_email: string | null;
  created_at: string;
  expires_at: string | null;
};

export default function PendingInvites() {
  const [invites, setInvites] = useState<PendingInvite[]>([]);
  const [err, setErr] = useState<string>("");
  const [isPending, startTransition] = useTransition();

  const supabase = useMemo(
    () =>
      createBrowserClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      ),
    []
  );

  async function load() {
    setErr("");
    const { data, error } = await supabase.rpc("get_my_pending_invites_rpc");
    if (error) return setErr(error.message);
    setInvites((data ?? []) as PendingInvite[]);
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function accept(token: string) {
    startTransition(async () => {
      setErr("");
      const { error } = await supabase.rpc("accept_invite_rpc", { token });
      if (error) return setErr(error.message);
      window.location.href = "/app/gate";
    });
  }

  if (err) {
    return (
      <div style={{ padding: 14, borderRadius: 14, border: "1px solid rgba(255,80,80,0.35)", background: "rgba(180,0,0,0.18)" }}>
        <b>Error:</b> {err}
      </div>
    );
  }

  if (!invites || invites.length === 0) {
    return (
      <div style={{ padding: 14, borderRadius: 14, border: "1px solid rgba(255,255,255,0.12)", background: "rgba(255,255,255,0.06)" }}>
        <div style={{ fontWeight: 900, marginBottom: 6 }}>No invites found</div>
        <div style={{ fontSize: 13, opacity: 0.85 }}>
          If you were invited, ask the sender to resend the invite link, or use the Accept Invite page.
        </div>
        <a
          href="/app/accept-invite"
          style={{
            display: "inline-block",
            marginTop: 10,
            padding: "12px 14px",
            borderRadius: 10,
            border: "1px solid rgba(255,255,255,0.18)",
            background: "rgba(0,0,0,0.25)",
            color: "white",
            textDecoration: "none",
            fontWeight: 800,
          }}
        >
          Accept invite
        </a>
      </div>
    );
  }

  return (
    <div style={{ display: "grid", gap: 10 }}>
      <div style={{ fontWeight: 900, fontSize: 16 }}>Pending invites</div>

      {invites.map((i) => (
        <div key={i.invite_id} style={{ padding: 12, borderRadius: 12, border: "1px solid rgba(255,255,255,0.12)", background: "rgba(255,255,255,0.06)" }}>
          <div style={{ fontWeight: 900 }}>{i.workspace_name}</div>
          <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
            invited role: {i.invited_role} | invited by: <b>{i.inviter_email ?? "unknown"}</b>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
            <button
              onClick={() => accept(i.token)}
              disabled={isPending}
              style={{
                padding: "10px 12px",
                borderRadius: 10,
                border: "1px solid rgba(255,255,255,0.18)",
                background: "rgba(0,0,0,0.25)",
                color: "white",
                cursor: "pointer",
                fontWeight: 800,
              }}
            >
              Accept
            </button>
            <button
              onClick={() => (window.location.href = `/app/accept-invite?token=${i.token}`)}
              disabled={isPending}
              style={{
                padding: "10px 12px",
                borderRadius: 10,
                border: "1px solid rgba(255,255,255,0.18)",
                background: "rgba(0,0,0,0.15)",
                color: "white",
                cursor: "pointer",
              }}
            >
              View details
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}