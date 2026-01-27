export const dynamic = "force-dynamic";
export const revalidate = 0;

import { headers } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import StatusClient from "./StatusClient";

function parseCookieHeader(header: string | null): { name: string; value: string }[] {
  if (!header) return [];
  return header
    .split(";")
    .map((p) => p.trim())
    .filter(Boolean)
    .map((kv) => {
      const eq = kv.indexOf("=");
      if (eq === -1) return { name: kv, value: "" };
      return { name: kv.slice(0, eq), value: decodeURIComponent(kv.slice(eq + 1)) };
    });
}

export default async function DealDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const deal_id = String(id ?? "");

  const h = await headers();
  const cookieHeader = h.get("cookie") ?? "";
  const cookiePairs = parseCookieHeader(cookieHeader);

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookiePairs; },
        setAll() { /* no-op */ },
      },
    }
  );

  const dbg = await supabase.rpc("debug_context_rpc");
  const dealRes = await supabase.rpc("get_deal", { deal_id });

  const deal = Array.isArray(dealRes.data) ? dealRes.data[0] : dealRes.data;

  if (!deal) {
    return (
      <main style={{ padding: 24 }}>
        <h1>Deal not found</h1>
        <pre style={{ whiteSpace: "pre-wrap" }}>
{JSON.stringify({
  deal_id,
  cookieHeader_len: cookieHeader.length,
  cookiePairs_len: cookiePairs.length,
  debug_context: dbg.data ?? dbg.error ?? null,
  get_deal: { data: dealRes.data, error: dealRes.error ?? null },
}, null, 2)}
        </pre>
      </main>
    );
  }

  return (
    <main style={{ padding: 24 }}>
      <h1>Deal</h1>

      <div style={{ marginTop: 12 }}>
        <div><b>ID:</b> {deal.id}</div>
        <div><b>Status:</b> {deal.status}</div>
        <div><b>Row version:</b> {deal.row_version}</div>
      </div>

      <div style={{ marginTop: 16 }}>
        <StatusClient dealId={deal.id} rowVersion={deal.row_version} />
      </div>
    </main>
  );
}
