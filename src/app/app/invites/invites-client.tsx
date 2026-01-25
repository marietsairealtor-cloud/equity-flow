"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { createBrowserClient } from "@supabase/ssr";

type InviteRow = {
  id: string;
  tenant_id: string;
  invited_email: string;
  invited_role: string;
  token: string;
  created_at: string;
  expires_at: string;
  revoked_at: string | null;
  accepted_at: string | null;
  accepted_by: string | null;
};

export default function InvitesClient({ tenant_id, workspace_name, role }: { tenant_id: string; workspace_name: string; role: string }) {
  const [email, setEmail] = useState("");
  const [isPending, startTransition] = useTransition();
  const [invites, setInvites] = useState<InviteRow[]>([]);
  const [err, setErr] = useState<string>("");

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
    const { data, error } = await supabase.rpc("get_invites_rpc");
    if (error) return setErr(error.message);
    setInvites((data ?? []) as InviteRow[]);
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function createInvite() {
    const e = email.trim();
    if (!e) return alert("email required");

    startTransition(async () => {
      setErr("");
      const { error } = await supabase.rpc("create_invite_rpc", { tenant_id, email: e });
      if (error) return setErr(error.message);
      setEmail("");
      await load();
    });
  }

  function revokeInvite(invite_id: string) {
    if (!confirm("Revoke this invite?")) return;

    startTransition(async () => {
      setErr("");
      const { error } = await supabase.rpc("revoke_invite_rpc", { invite_id });
      if (error) return setErr(error.message);
      await load();
    });
  }

  return (
    <div style={{ padding: 20, background: "#0b0f19", color: "white", minHeight: "100vh" }}>
      <div style={{ maxWidth: 860, margin: "0 auto" }}>
        <div style={{ fontSize: 22, fontWeight: 900, marginBottom: 6 }}>Invites</div>
        <div style={{ fontSize: 13, opacity: 0.85, marginBottom: 12 }}>
          Workspace: <b>{workspace_name}</b> | role: <b>{role}</b>
        </div>

        <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginBottom: 12 }}>
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="email@domain.com"
            style={{
              flex: "1 1 280px",
              padding: 12,
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(255,255,255,0.06)",
              color: "white",
            }}
          />
          <button
            onClick={createInvite}
            disabled={isPending}
            style={{
              padding: "12px 14px",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.18)",
              background: "rgba(0,0,0,0.25)",
              color: "white",
              cursor: "pointer",
              fontWeight: 800,
            }}
          >
            Create invite
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

        {err ? (
          <div style={{ padding: 12, borderRadius: 12, background: "rgba(180,0,0,0.18)", border: "1px solid rgba(255,80,80,0.35)", marginBottom: 12 }}>
            <b>Error:</b> {err}
          </div>
        ) : null}

        <div style={{ display: "grid", gap: 10 }}>
          {invites.length === 0 ? (
            <div style={{ opacity: 0.85 }}>No invites found.</div>
          ) : (
            invites.map((i) => {
              const status =
                i.revoked_at ? "revoked" :
                i.accepted_at ? "accepted" :
                (i.expires_at && new Date(i.expires_at).getTime() < Date.now()) ? "expired" :
                "open";

              return (
                <div key={i.id} style={{ padding: 12, borderRadius: 12, border: "1px solid rgba(255,255,255,0.12)", background: "rgba(255,255,255,0.06)" }}>
                  <div style={{ fontWeight: 900 }}>{i.invited_email}</div>
                  <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
                    status: {status} | role: {i.invited_role}
                  </div>
                  <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
                    token: <code style={{ background: "rgba(0,0,0,0.35)", padding: "2px 6px", borderRadius: 8 }}>{i.token}</code>
                  </div>
                  <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
                    <button
                      onClick={() => navigator.clipboard.writeText(i.token)}
                      disabled={isPending}
                      style={{ padding: "10px 12px", borderRadius: 10, border: "1px solid rgba(255,255,255,0.18)", background: "rgba(0,0,0,0.15)", color: "white", cursor: "pointer" }}
                    >
                      Copy token
                    </button>
                    <button
                      onClick={() => revokeInvite(i.id)}
                      disabled={isPending || status !== "open"}
                      style={{ padding: "10px 12px", borderRadius: 10, border: "1px solid rgba(255,255,255,0.18)", background: status !== "open" ? "rgba(255,255,255,0.08)" : "rgba(180,0,0,0.35)", color: "white", cursor: status !== "open" ? "not-allowed" : "pointer", opacity: status !== "open" ? 0.6 : 1, fontWeight: 800 }}
                      title={status !== "open" ? "Only open invites can be revoked" : "Revoke invite"}
                    >
                      Revoke
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}