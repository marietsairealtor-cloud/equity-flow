import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { tenant_id, days } = await req.json().catch(() => ({} as any));

  if (!tenant_id) {
    return NextResponse.json({ error: "tenant_id required" }, { status: 400 });
  }

  const { error } = await supabase.rpc("start_trial", {
    p_tenant_id: tenant_id,
    p_days: typeof days === "number" ? days : 14,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  return NextResponse.json({ ok: true });
}
