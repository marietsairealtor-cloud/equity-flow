import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

type Ctx = { params: Promise<{ id: string }> };

export async function POST(req: NextRequest, ctx: Ctx) {
  const { id } = await ctx.params;

  let body: any = null;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 });
  }

  const status = String(body?.status ?? "");
  const expected = body?.expected_row_version;
  const expected_row_version =
    expected === null || expected === undefined ? null : Number(expected);

  if (!status) return NextResponse.json({ error: "STATUS_REQUIRED" }, { status: 400 });
  if (expected_row_version !== null && !Number.isFinite(expected_row_version)) {
    return NextResponse.json({ error: "INVALID_ROW_VERSION" }, { status: 400 });
  }

  const supabase = await supabaseServer();
  const r = await supabase.rpc("set_deal_status", {
    p_deal_id: id,
    p_status: status,
    p_expected_row_version: expected_row_version,
  });

  if (r.error) return NextResponse.json({ error: r.error.message }, { status: 400 });

  return NextResponse.json({ ok: true, deal: r.data?.[0] ?? null });
}