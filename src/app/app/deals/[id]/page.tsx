import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";

export default async function DealDetailPage({ params, searchParams }: any) {
  const supabase = await supabaseServer();

  const deal_id = String(params?.id ?? "");
  if (!deal_id) redirect("/app/deals?err=MISSING_DEAL_ID");

  const { data, error } = await supabase.rpc("get_deal", { deal_id });
  const deal = Array.isArray(data) ? data[0] : null;

  const err = String(searchParams?.err ?? "");

  if (error) {
    return (
      <div style={{ padding: 16 }}>
        <h1>Deal</h1>
        <div style={{ color: "crimson" }}>Error: {error.message}</div>
        <div style={{ marginTop: 12 }}><a href="/app/deals">Back</a></div>
      </div>
    );
  }

  if (!deal) {
    return (
      <div style={{ padding: 16 }}>
        <h1>Deal</h1>
        <div>Not found.</div>
        <div style={{ marginTop: 12 }}><a href="/app/deals">Back</a></div>
      </div>
    );
  }

  return (
    <div style={{ padding: 16 }}>
      <h1>Deal</h1>

      {err && <div style={{ color: "crimson", marginBottom: 12 }}>Error: {err}</div>}

      <div><b>ID:</b> {deal.id}</div>
      <div><b>Status:</b> {String(deal.status)}</div>
      <div><b>Market area:</b> {String(deal.market_area)}</div>
      <div><b>Row version:</b> {String(deal.row_version)}</div>

      <hr style={{ margin: "16px 0" }} />

      <h2>Update status</h2>
      <form method="post" action={`/app/deals/${deal.id}/status`}>
        <input type="hidden" name="p_expected_row_version" value={deal.row_version} />
        <select name="status" defaultValue={String(deal.status)}>
          <option value="New">New</option>
          <option value="Contacted">Contacted</option>
          <option value="Appointment Set">Appointment Set</option>
          <option value="Offer Made">Offer Made</option>
          <option value="Under Contract">Under Contract</option>
          <option value="Closed/Assigned">Closed/Assigned</option>
          <option value="Dead">Dead</option>
        </select>
        <button type="submit" style={{ marginLeft: 8 }}>Save</button>
      </form>

      <div style={{ marginTop: 16 }}>
        <a href="/app/deals">Back to deals</a>
      </div>
    </div>
  );
}