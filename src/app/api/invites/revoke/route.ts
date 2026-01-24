import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();
  const { invite_id } = await req.json().catch(() => ({} as any));

  if (!invite_id) {
    return NextResponse.json({ error: "invite_id required" }, { status: 400 });
  }

  const { error } = await supabase.rpc("revoke_invite", { p_invite_id: invite_id });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ ok: true });
}
