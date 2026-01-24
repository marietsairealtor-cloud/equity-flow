import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();

  const { token } = await req.json().catch(() => ({} as any));

  if (!token) {
    return NextResponse.json({ error: "token required" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("accept_invite", {
    p_token: token,
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  const row = Array.isArray(data) ? data[0] : data;
  return NextResponse.json({ accepted: row });
}
