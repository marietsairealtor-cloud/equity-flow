import { supabaseServer } from "@/lib/supabase-server";
import StatusButtons from "./StatusButtons";

export const dynamic = "force-dynamic";

export default async function DealPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const supabase = await supabaseServer();

  const { data: deal, error } = await supabase
    .from("deals")
    .select("id,status,created_at")
    .eq("id", id)
    .single();

  return (
    <main>
      <h1>Deal</h1>

      {error && <p style={{ color: "crimson" }}>{error.message}</p>}

      {deal && (
        <>
          <ul>
            <li>id: {deal.id}</li>
            <li>status: {deal.status}</li>
            <li>created_at: {deal.created_at}</li>
          </ul>

          <StatusButtons id={deal.id} />
        </>
      )}

      <p>
        <a href="/app/deals">Back to deals</a>
      </p>
    </main>
  );
}
