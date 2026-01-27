import { redirect } from "next/navigation";
import { getEntitlementsServer } from "@/lib/entitlements/server";

export default async function HomePage() {
  const ents = await getEntitlementsServer();
  if (!ents.length) redirect("/app/workspace");

  const e = ents[0];

  return (
    <div style={{ background: "#000", color: "#fff", minHeight: "100vh" }}>
      <div style={{ padding: 24, maxWidth: 820 }}>
        <h1 style={{ fontSize: 22, fontWeight: 800, marginBottom: 12 }}>App</h1>

        <div style={{ lineHeight: 1.8 }}>
          <div><b>Workspace:</b> {e.workspace_name ?? "-"}</div>
          <div><b>role:</b> {e.role ?? "-"}</div>
          <div><b>tier:</b> {e.tier ?? "-"}</div>
          <div><b>status:</b> {e.status ?? "-"}</div>
          <div><b>trial_ends_at:</b> {e.trial_ends_at ?? "-"}</div>
        </div>

        <div style={{ marginTop: 18, opacity: 0.85 }}>
          <a style={{ color: "#fff" }} href="/app/debug/tenant-status">/app/debug/tenant-status</a>
        </div>
      </div>
    </div>
  );
}