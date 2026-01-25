import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const form = await req.formData();
  const invite_id = String(form.get("invite_id") ?? "");

  const supabase = await supabaseServer();
  const { error } = await supabase.rpc("accept_invite_by_id_rpc", { invite_id });

  if (error) {
    return NextResponse.redirect(
      new URL(`/app/workspace?err=${encodeURIComponent(error.message)}`, req.url),
      { status: 303 }
    );
  }

  return NextResponse.redirect(new URL("/app/gate", req.url), { status: 303 });
}