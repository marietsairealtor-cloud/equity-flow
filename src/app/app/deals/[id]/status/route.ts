import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: NextRequest, ctx: { params: Promise<{ id: string }> }) {
  const { id } = await ctx.params;
  const supabase = await supabaseServer();

  let body: any = null;
  try { body = await req.json(); } catch { return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 }); }

  const status = String(body?.status ?? "");
  if (!status) return NextResponse.json({ error: "STATUS_REQUIRED" }, { status: 400 });

  const u = await supabase.from("deals").update({ status }).eq("id", id).select("id").single();
  if (u.error) return NextResponse.json({ error: u.error.message }, { status: 400 });

  return NextResponse.json({ ok: true });
}