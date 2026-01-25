import { supabaseServer } from "@/lib/supabase/server";

export default async function DebugPage() {
  const supabase = await supabaseServer();

  const me = await supabase.auth.getUser();
  const userId = me.data.user?.id ?? null;
  const email = me.data.user?.email ?? null;

  const ent = await supabase.rpc("get_entitlements");

  let profile: any = null;
  if (userId) {
    const p = await supabase.from("user_profiles").select("user_id,current_tenant_id").eq("user_id", userId).maybeSingle();
    profile = p.error ? { error: p.error.message } : p.data;
  }

  let memberships: any = null;
  if (userId) {
    const m = await supabase.from("tenant_memberships").select("tenant_id,role,created_at").eq("user_id", userId).order("created_at", { ascending: false });
    memberships = m.error ? { error: m.error.message } : m.data;
  }

  const out = {
    me: { userId, email, error: me.error?.message ?? null },
    entitlements: ent.error ? { error: ent.error.message } : ent.data,
    profile,
    memberships,
  };

  return (
    <div style={{ padding: 16, color: "#eee", maxWidth: 1100 }}>
      <div style={{ fontSize: 20, fontWeight: 800, color: "#fff" }}>Debug</div>
      <pre
        style={{
          marginTop: 12,
          padding: 12,
          borderRadius: 12,
          border: "1px solid #2a2a2a",
          background: "#0f0f0f",
          overflow: "auto",
          fontSize: 12,
          lineHeight: 1.35,
          whiteSpace: "pre-wrap",
        }}
      >
        {JSON.stringify(out, null, 2)}
      </pre>
    </div>
  );
}