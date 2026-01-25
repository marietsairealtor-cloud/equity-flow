import { supabaseServer } from "@/lib/supabase/server";

export default async function HomePage() {
  const supabase = await supabaseServer();
  const ent = await supabase.rpc("get_entitlements");
  const e = ent.data?.[0];

  return (
    <div style={{ padding: 16 }}>
      <div style={{ fontSize: 20, fontWeight: 800 }}>App</div>

      <div style={{ marginTop: 10, color: "#eee", display: "grid", gap: 4 }}>
        <div>Workspace: {e?.workspace_name ?? "-"}</div>
        <div>role: {e?.role ?? "-"}</div>
        <div>tier: {e?.tier ?? "-"}</div>
        <div>status: {e?.status ?? "-"}</div>
        <div>trial_ends_at: {e?.trial_ends_at ?? "-"}</div>
      </div>
    </div>
  );
}
