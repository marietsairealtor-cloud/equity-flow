"use client";

import { useState } from "react";
import { supabaseBrowser } from "@/lib/supabase/client";

type PendingInvite = {
  invite_id: string;
  tenant_id: string;
  workspace_name: string | null;
  invited_role: string | null;
  inviter_email: string | null;
  created_at: string;
};

export default function AcceptInviteClient(props: { invites: PendingInvite[]; error: string | null }) {
  const [busyId, setBusyId] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(props.error);

  async function accept(inviteId: string) {
    setErr(null);
    setBusyId(inviteId);
    try {
      const supabase = supabaseBrowser();
      const { data, error } = await supabase.rpc("accept_my_invite_rpc", { p_invite_id: inviteId });
      if (error) throw error;

      // accept_invite() should add membership + set current tenant via existing flow (if it does).
      // Route through gate to land correctly.
      window.location.href = "/app/gate";
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div style={{ padding: 24, display: "grid", gap: 12, maxWidth: 720 }}>
      <h1 style={{ margin: 0 }}>Accept invite</h1>

      {err ? <pre style={{ whiteSpace: "pre-wrap", color: "crimson" }}>{err}</pre> : null}

      {props.invites.length === 0 ? (
        <div>No pending invites.</div>
      ) : (
        <div style={{ display: "grid", gap: 10 }}>
          {props.invites.map((i) => (
            <div
              key={i.invite_id}
              style={{ border: "1px solid #ddd", borderRadius: 12, padding: 12, display: "grid", gap: 6 }}
            >
              <div style={{ fontWeight: 600 }}>
                Invite to: {i.workspace_name ?? i.tenant_id}
              </div>
              <div>From: {i.inviter_email ?? "(unknown)"}</div>
              <div>Role: {i.invited_role ?? "(unspecified)"}</div>
              <button
                onClick={() => accept(i.invite_id)}
                disabled={busyId === i.invite_id}
                style={{ padding: 10, border: "1px solid #ccc", borderRadius: 8, cursor: "pointer", width: 140 }}
              >
                {busyId === i.invite_id ? "Accepting..." : "Accept"}
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
