import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await supabaseServer();
  let body: any = null;
  try { body = await req.json(); } catch { return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 }); }

  const tenant_id = String(body?.tenant_id ?? "");
  if (!tenant_id) return NextResponse.json({ error: "TENANT_ID_REQUIRED" }, { status: 400 });

  const r = await supabase.rpc("set_current_tenant", { p_tenant_id: tenant_id });
  if (r.error) return NextResponse.json({ error: r.error.message }, { status: 400 });

  return NextResponse.json({ ok: true });
}