import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const form = await req.formData();
  const seat_limit = Number(form.get("seat_limit") ?? 0);

  const supabase = await supabaseServer();
  const { error } = await supabase.rpc("owner_set_seat_limit", { p_seat_limit: seat_limit });

  if (error) {
    return NextResponse.redirect(
      new URL(`/app/workspace?err=${encodeURIComponent(error.message)}`, req.url),
      { status: 303 }
    );
  }

  return NextResponse.redirect(new URL("/app/invites", req.url), { status: 303 });
}