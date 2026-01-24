import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { tenant_id, user_id } = await req.json().catch(() => ({} as any));

  if (!tenant_id || !user_id) {
    return NextResponse.json({ error: "tenant_id and user_id required" }, { status: 400 });
  }

  const { error } = await supabase.rpc("remove_member", {
    p_Workspace: tenant_id,
    p_user_id: user_id,
  });

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  return NextResponse.json({ ok: true });
}

