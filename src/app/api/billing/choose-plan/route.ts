import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await supabaseServer();

  let body: any = null;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 });
  }

  const tier = String(body?.tier ?? "");
  if (!tier) return NextResponse.json({ error: "TIER_REQUIRED" }, { status: 400 });

  const r = await supabase.rpc("choose_plan_and_start_trial", { p_tier: tier });
  if (r.error) return NextResponse.json({ error: r.error.message }, { status: 400 });

  return NextResponse.json({ ok: true, tenant: r.data?.[0] ?? null });
}