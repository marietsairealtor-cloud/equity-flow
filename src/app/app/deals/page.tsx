import Link from "next/link";
import { supabaseServer } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function DealsPage({ searchParams }: { searchParams: Promise<any> }) {
  const sp = await searchParams;

  const supabase = await supabaseServer();
  const { data, error } = await supabase.rpc("list_deals");

  const deals = Array.isArray(data) ? data : [];
  const err = String(sp?.err ?? "") || (error ? error.message : "");

  return (
    <div style={{ padding: 16, display: "grid", gap: 12 }}>
      <h1 style={{ margin: 0 }}>Deals</h1>

      {err ? (
        <div style={{ padding: 10, border: "1px solid #c00", borderRadius: 8, color: "#c00" }}>
          {err}
        </div>
      ) : null}

      <div style={{ display: "flex", gap: 8 }}>
        <Link
          href="/app/deals?do=create"
          style={{ padding: "8px 10px", border: "1px solid #111", borderRadius: 8, textDecoration: "none" }}
        >
          Create (legacy)
        </Link>
        <Link
          href="/app/upgrade"
          style={{ padding: "8px 10px", border: "1px solid #111", borderRadius: 8, textDecoration: "none" }}
        >
          Upgrade
        </Link>
      </div>

      <div style={{ display: "grid", gap: 8 }}>
        {deals.map((d: any) => (
          <Link
            key={d.id}
            href={`/app/deals/${d.id}`}
            style={{ padding: 10, border: "1px solid #ddd", borderRadius: 10, textDecoration: "none" }}
          >
            <div style={{ fontWeight: 600 }}>{d.id}</div>
            <div style={{ fontSize: 12, color: "#555" }}>
              status: {String(d.status)} | row_version: {String(d.row_version)}
            </div>
          </Link>
        ))}
        {deals.length === 0 ? <div style={{ color: "#555" }}>No deals yet.</div> : null}
      </div>
    </div>
  );
}