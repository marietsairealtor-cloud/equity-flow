import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function POST(request: Request) {
  const { tenant_id } = await request.json();
  const supabase = await supabaseServer();

  const { error } = await supabase.rpc("set_current_tenant", { p_Workspace: tenant_id });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ ok: true });
}
