import { supabaseServer } from ""@/lib/supabase/server"";
import StatusClient from ""./StatusClient"";

export default async function DealDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await supabaseServer();

  const d = await supabase.from(""deals"").select(""id,status,created_at"").eq(""id"", id).single();

  if (d.error) {
    return <div style={{ padding: 16, color: ""#eee"" }}>Error: {d.error.message}</div>;
  }

  return (
    <div style={{ padding: 16, color: ""#eee"", display: ""grid"", gap: 12, maxWidth: 900 }}>
      <div style={{ display: ""flex"", justifyContent: ""space-between"", alignItems: ""center"", gap: 10 }}>
        <div style={{ fontSize: 20, fontWeight: 800, color: ""#fff"" }}>Deal</div>
        <a href=""/app/deals"" style={{ fontSize: 13, color: ""#9cc9ff"", textDecoration: ""none"" }}>Back</a>
      </div>

      <div style={{ padding: ""12px 12px"", borderRadius: 12, border: ""1px solid #2a2a2a"", background: ""#0f0f0f"" }}>
        <div style={{ fontSize: 13, color: ""#bbb"" }}>id</div>
        <div style={{ fontSize: 13, fontWeight: 800, color: ""#fff"" }}>{d.data.id}</div>

        <div style={{ marginTop: 12 }}>
          <StatusClient dealId={d.data.id} status={d.data.status} />
        </div>

        <div style={{ marginTop: 12 }}>
          <a href={/app/deals//documents} style={{ fontSize: 13, color: ""#9cc9ff"", textDecoration: ""none"" }}>
            Documents
          </a>
        </div>
      </div>
    </div>
  );
}