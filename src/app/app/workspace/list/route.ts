import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function GET() {
  const supabase = await supabaseServer();

  const { data: memberships, error } = await supabase
    .from("tenant_memberships")
    .select("tenant_id, role");

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ memberships: memberships ?? [] });
}
