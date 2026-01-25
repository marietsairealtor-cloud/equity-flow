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

  const seat_limit = Number(body?.seat_limit);
  if (!Number.isFinite(seat_limit) || seat_limit < 1) {
    return NextResponse.json({ error: "INVALID_SEAT_LIMIT" }, { status: 400 });
  }

  const r = await supabase.rpc("set_current_tenant_seat_limit", { p_seat_limit: seat_limit });
  if (r.error) return NextResponse.json({ error: r.error.message }, { status: 400 });

  return NextResponse.json({ ok: true, seats: r.data?.[0] ?? null });
}