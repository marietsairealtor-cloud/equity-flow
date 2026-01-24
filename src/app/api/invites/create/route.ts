import { NextResponse } from "next/server";
import { createSupabaseServerClient } from "@/lib/supabase/serverClient";

export async function POST(req: Request) {
  const supabase = await createSupabaseServerClient();

  const { tenant_id, email, role } = await req.json().catch(() => ({} as any));

  if (!tenant_id || !email) {
    return NextResponse.json({ error: "tenant_id and email required" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("create_invite", {
    p_Workspace: tenant_id,
    p_email: email,
    p_role: role ?? "member",
    p_expires_in: "7 days",
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  const row = Array.isArray(data) ? data[0] : data;
  return NextResponse.json({ invite: row });
}

