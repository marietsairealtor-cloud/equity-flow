"use client";

import { useTransition } from "react";
import { createBrowserClient } from "@supabase/ssr";

export default function WorkspacePicker({ workspaces }: { workspaces: any[] }) {
  const [isPending, startTransition] = useTransition();

  const supabase = createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  async function selectTenant(tenant_id: string) {
    startTransition(async () => {
      const { error } = await supabase.rpc("set_current_tenant", { p_tenant_id: tenant_id });
      if (error) {
        alert(error.message);
        return;
      }
      window.location.href = "/app/gate";
    });
  }

  return (
    <div style={{ display: "grid", gap: 12 }}>
      {workspaces.map((w: any) => (
        <button
          key={w.tenant_id}
          onClick={() => selectTenant(w.tenant_id)}
          disabled={isPending}
          style={{
            textAlign: "left",
            padding: 14,
            borderRadius: 12,
            border: "1px solid rgba(255,255,255,0.12)",
            background: "rgba(255,255,255,0.06)",
            color: "white",
            cursor: "pointer",
          }}
        >
          <div style={{ fontWeight: 700, fontSize: 16 }}>{w.workspace_name}</div>
          <div style={{ fontSize: 12, opacity: 0.85, marginTop: 4 }}>
            role: {w.role} • tier: {w.tier} • status: {w.status}
          </div>
          {w.trial_ends_at ? (
            <div style={{ fontSize: 12, opacity: 0.75, marginTop: 4 }}>
              trial ends: {String(w.trial_ends_at)}
            </div>
          ) : null}
        </button>
      ))}
    </div>
  );
}