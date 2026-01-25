import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: NextRequest) {
  const supabase = await supabaseServer();

  let body: any = null;
  try { body = await req.json(); } catch { return NextResponse.json({ error: "INVALID_JSON" }, { status: 400 }); }

  const tenant_id = String(body?.tenant_id ?? "");
  const user_id = String(body?.user_id ?? "");
  const role = String(body?.role ?? "");

  if (!tenant_id || !user_id || !role) {
    return NextResponse.json({ error: "ARG_REQUIRED" }, { status: 400 });
  }

  const r = await supabase.rpc("set_member_role", {
    p_tenant_id: tenant_id,
    p_user_id: user_id,
    p_role: role,
  });

  if (r.error) return NextResponse.json({ error: r.error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}