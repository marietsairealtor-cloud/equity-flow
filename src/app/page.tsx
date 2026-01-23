"use client";

import { useEffect, useState } from "react";
import { supabaseBrowser } from "@/lib/supabase/client";

export default function Page() {
  const [status, setStatus] = useState("checking...");

  useEffect(() => {
    (async () => {
      const supabase = supabaseBrowser();
      const { data, error } = await supabase.from("tenants").select("id").limit(1);
      setStatus(error ? `error: ${error.message}` : `ok: ${data?.length ?? 0} row(s)`);
    })();
  }, []);

  return (
    <main style={{ padding: 24 }}>
      <h1>Equity Flow</h1>
      <p>Supabase test: {status}</p>
    </main>
  );
}
