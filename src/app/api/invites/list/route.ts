import { NextRequest, NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(_req: NextRequest) {
  const supabase = await supabaseServer();
  const ent = await supabase.rpc("get_entitlements");
  const tenantId = (ent.data?.[0]?.tenant_id as string | null) ?? null;
  if (!tenantId) return NextResponse.json({ invites: [] });

  const inv = await supabase
    .from("tenant_invites")
    .select("id,email,role,status,token,created_at")
    .eq("tenant_id", tenantId)
    .order("created_at", { ascending: false });

  if (inv.error) return NextResponse.json({ error: inv.error.message }, { status: 400 });
  return NextResponse.json({ invites: inv.data ?? [] });
}