import Link from "next/link";
import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

export default async function DealsPage({ searchParams }: any) {
  const supabase = await supabaseServer();

  const { data: ents } = await supabase.rpc("get_entitlements");
  const ent = Array.isArray(ents) ? ents[0] : null;

  if (!ent?.tenant_id) redirect("/app/workspace?err=NO_TENANT_SELECTED");

  const { data, error } = await supabase.rpc("list_deals");
  const deals = Array.isArray(data) ? data : [];

  const err = String(searchParams?.err ?? "");

  return (
    <div style={{ padding: 16 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <h1>Deals</h1>
        <form method="post" action="/auth/logout"><button type="submit">Logout</button></form>
      </div>

      {err && <div style={{ color: "crimson", marginBottom: 12 }}>Error: {err}</div>}
      {error && <div style={{ color: "crimson", marginBottom: 12 }}>Error: {error.message}</div>}

      <form method="post" action="/app/deals/create" style={{ display: "flex", gap: 8, marginBottom: 12 }}>
        <select name="status" defaultValue="New">
          <option value="New">New</option>
          <option value="Contacted">Contacted</option>
          <option value="Appointment Set">Appointment Set</option>
          <option value="Offer Made">Offer Made</option>
          <option value="Under Contract">Under Contract</option>
          <option value="Closed/Assigned">Closed/Assigned</option>
          <option value="Dead">Dead</option>
        </select>
        <input name="market_area" placeholder="market area" defaultValue="default" />
        <button type="submit">Create</button>
      </form>

      <ul style={{ padding: 0, listStyle: "none" }}>
        {deals.map((d: any) => (
          <li key={d.id} style={{ padding: 8, borderTop: "1px solid #eee" }}>
            <Link href={`/app/deals/${d.id}`}>{d.id}</Link>
            {" "} | {String(d.status)} | v{String(d.row_version)}
          </li>
        ))}
      </ul>
    </div>
  );
}