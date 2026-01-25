"use client";

import { useMemo, useState } from "react";

type InviteRow = {
  id: string;
  email: string;
  role: string;
  status: string;
  token: string | null;
  created_at: string;
};

const UI = {
  page: { padding: 16, maxWidth: 900, color: "#eee" as const },
  card: { padding: "12px 12px", borderRadius: 12, border: "1px solid #2a2a2a", background: "#0f0f0f" as const },
  subtle: { fontSize: 13, color: "#bbb" as const },
  h1: { fontSize: 20, fontWeight: 800, color: "#fff" as const },
  label: { fontSize: 13, fontWeight: 700, color: "#fff" as const },

  input: {
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#121212",
    color: "#eee",
    minWidth: 260,
  } as const,

  select: {
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#121212",
    color: "#eee",
  } as const,

  btn: {
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#1a1a1a",
    color: "#eee",
  } as const,

  btnSmall: {
    padding: "8px 10px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#1a1a1a",
    color: "#eee",
  } as const,

  link: { fontSize: 13, color: "#9cc9ff" as const, textDecoration: "none" as const },
};

export default function InvitesClient(props: {
  tenantId: string;
  workspaceName: string;
  myRole: string;
  seatLimit: number;
  seatCount: number;
  initialInvites: InviteRow[];
}) {
  const [email, setEmail] = useState("");
  const [role, setRole] = useState("member");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const [invites, setInvites] = useState<InviteRow[]>(props.initialInvites ?? []);
  const [showAll, setShowAll] = useState(false);

  const isAdmin = props.myRole === "owner" || props.myRole === "admin";
  const full = props.seatLimit > 0 && props.seatCount >= props.seatLimit;

  const visibleInvites = useMemo(() => {
    if (showAll) return invites;
    return invites.filter((i) => i.status === "open");
  }, [invites, showAll]);

  async function refresh() {
    const res = await fetch("/api/invites/list", { method: "POST" });
    if (!res.ok) return;
    const j = await res.json();
    if (Array.isArray(j?.invites)) setInvites(j.invites);
  }

  async function setSeatLimit(n: number) {
    setErr("");
    setBusy(true);
    try {
      const res = await fetch("/api/seats/set-limit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ seat_limit: n }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "SET_SEAT_LIMIT_FAILED");
      window.location.reload();
    } catch (e: any) {
      setErr(e?.message ?? "SET_SEAT_LIMIT_FAILED");
      setBusy(false);
    }
  }

  async function createInvite() {
    setErr("");
    if (!email.trim()) {
      setErr("EMAIL_REQUIRED");
      return;
    }
    if (full) {
      setErr("SEAT_LIMIT_REACHED");
      return;
    }

    setBusy(true);
    try {
      const res = await fetch("/api/invites/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), role }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "CREATE_INVITE_FAILED");
      setEmail("");
      await refresh();
      window.location.reload();
    } catch (e: any) {
      setErr(e?.message ?? "CREATE_INVITE_FAILED");
    } finally {
      setBusy(false);
    }
  }

  async function revokeInvite(id: string) {
    setErr("");
    setBusy(true);
    try {
      const res = await fetch("/api/invites/revoke", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ invite_id: id }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j?.error || "REVOKE_FAILED");
      await refresh();
    } catch (e: any) {
      setErr(e?.message ?? "REVOKE_FAILED");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={UI.page}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <div>
          <div style={UI.h1}>Invites</div>
          <div style={UI.subtle}>
            Workspace: <b style={{ color: "#fff" }}>{props.workspaceName || "-"}</b> • Seats:{" "}
            <b style={{ color: "#fff" }}>{props.seatCount}/{props.seatLimit}</b>
            {full ? <span style={{ marginLeft: 8 }}>• <b style={{ color: "#fff" }}>FULL</b></span> : null}
          </div>
        </div>
        <a href="/app/workspace" style={UI.link}>Back to Workspace</a>
      </div>

      {isAdmin ? (
        <div style={{ marginTop: 10, display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
          <div style={UI.subtle}>Seat limit controls:</div>
          <button disabled={busy} onClick={() => setSeatLimit(props.seatCount)} style={UI.btnSmall}>
            Set limit = count (simulate FULL)
          </button>
          <button disabled={busy} onClick={() => setSeatLimit(100)} style={UI.btnSmall}>
            Set limit = 100
          </button>
        </div>
      ) : null}

      <div style={{ marginTop: 14, ...UI.card }}>
        <div style={{ ...UI.label, marginBottom: 8 }}>Create invite</div>
        <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="email@domain.com"
            style={UI.input}
            disabled={busy || full}
          />
          <select value={role} onChange={(e) => setRole(e.target.value)} style={UI.select} disabled={busy || full}>
            <option value="member">member</option>
            <option value="admin">admin</option>
          </select>
          <button onClick={createInvite} disabled={busy || full} style={UI.btn}>
            {busy ? "Working..." : full ? "Seat limit reached" : "Create"}
          </button>

          <label style={{ ...UI.subtle, display: "flex", alignItems: "center", gap: 6 }}>
            <input type="checkbox" checked={showAll} onChange={(e) => setShowAll(e.target.checked)} />
            show all
          </label>
        </div>

        {err ? (
          <div
            style={{
              marginTop: 10,
              padding: "10px 12px",
              borderRadius: 10,
              border: "1px solid #7a2a2a",
              background: "#1a0f0f",
              fontSize: 12,
              whiteSpace: "pre-wrap",
              color: "#ffd0d0",
            }}
          >
            {err}
          </div>
        ) : null}
      </div>

      <div style={{ marginTop: 14, display: "grid", gap: 8 }}>
        {visibleInvites.length === 0 ? (
          <div style={UI.subtle}>No invites.</div>
        ) : (
          visibleInvites.map((i) => (
            <div key={i.id} style={UI.card}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center" }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "#fff" }}>{i.email}</div>
                  <div style={{ fontSize: 12, color: "#bbb" }}>
                    role: <b style={{ color: "#fff" }}>{i.role}</b> • status:{" "}
                    <b style={{ color: "#fff" }}>{i.status}</b> • {i.created_at}
                  </div>
                </div>
                <button onClick={() => revokeInvite(i.id)} disabled={busy || i.status !== "open"} style={UI.btnSmall}>
                  Revoke
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}