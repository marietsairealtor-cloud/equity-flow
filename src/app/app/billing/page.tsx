import { supabaseServer } from "@/lib/supabase/server";

type EntRow = {
  tenant_id: string | null;
  workspace_name: string | null;
  role: string | null;
  tier: string | null;
  status: "pending" | "trialing" | "active" | "past_due" | "canceled" | "locked" | string;
  trial_ends_at: string | null;
};

export default async function BillingPage() {
  const supabase = await supabaseServer();
  const { data, error } = await supabase.rpc("get_entitlements");

  if (error) {
    return (
      <div style={{ padding: 16 }}>
        <h1 style={{ fontSize: 22, fontWeight: 700 }}>Billing</h1>
        <div style={{ marginTop: 12, fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace", fontSize: 12 }}>
          NOT_LOGGED_IN
        </div>
      </div>
    );
  }

  const ent = (data?.[0] as EntRow | undefined);

  return (
    <div style={{ padding: 16, maxWidth: 720 }}>
      <h1 style={{ fontSize: 22, fontWeight: 700, marginBottom: 8 }}>Billing</h1>

      <div style={{ fontSize: 13, color: "#444", marginBottom: 14 }}>
        Workspace: <b>{ent?.workspace_name ?? "-"}</b> • Status: <b>{ent?.status ?? "-"}</b>
      </div>

      {ent?.status === "pending" ? (
        <div style={{ display: "grid", gap: 10 }}>
          <div style={{ fontSize: 14 }}>
            Your workspace is created but not activated yet.
          </div>
          <a
            href="/app/upgrade"
            style={{
              display: "inline-block",
              padding: "10px 12px",
              borderRadius: 10,
              border: "1px solid #ddd",
              background: "white",
              width: "fit-content",
              textDecoration: "none",
              color: "black",
            }}
          >
            Upgrade & Save (start trial)
          </a>
        </div>
      ) : ent?.status === "trialing" ? (
        <div style={{ display: "grid", gap: 8 }}>
          <div style={{ fontSize: 14 }}>Trial is active.</div>
          <div style={{ fontSize: 13, color: "#444" }}>
            Trial ends: <b>{ent.trial_ends_at ?? "-"}</b>
          </div>
        </div>
      ) : ent?.status === "active" ? (
        <div style={{ fontSize: 14 }}>Your subscription is active.</div>
      ) : ent?.status === "past_due" ? (
        <div style={{ fontSize: 14 }}>Payment required. Access is restricted.</div>
      ) : ent?.status === "canceled" ? (
        <div style={{ fontSize: 14 }}>Subscription ended. Access is off.</div>
      ) : ent?.status === "locked" ? (
        <div style={{ fontSize: 14 }}>Workspace is locked. Contact support.</div>
      ) : (
        <div style={{ fontSize: 14 }}>Billing status unknown.</div>
      )}
    </div>
  );
}
