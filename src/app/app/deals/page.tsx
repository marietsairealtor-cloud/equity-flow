import { supabaseServer } from "@/lib/supabase-server";
import LogoutButton from "../LogoutButton";
import CreateDealButton from "./CreateDealButton";

export const dynamic = "force-dynamic";

export default async function DealsPage() {
  const supabase = await supabaseServer();

  const { data: deals, error } = await supabase
    .from("deals")
    .select("id,status,created_at")
    .order("created_at", { ascending: false })
    .limit(20);

  return (
    <main>
      <h1>Deals</h1>

      <CreateDealButton />

      {error && <p style={{ color: "crimson" }}>{error.message}</p>}

      <ul>
        {(deals ?? []).map((d) => (
          <li key={d.id}>
            <a href={`/app/deals/${d.id}`}>{d.id}</a> <span style={{ marginLeft: 10 }}><a href={`/app/deals/${d.id}/documents`}>Documents</a></span>{" "}
            — {d.status} — {d.created_at}
          </li>
        ))}
      </ul>

      <LogoutButton />
    </main>
  );
}
