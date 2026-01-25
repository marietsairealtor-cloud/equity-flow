import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: Request, ctx: any) {
  const deal_id = String(ctx?.params?.id ?? "");
  const form = await req.formData();

  const status = String(form.get("status") ?? "");
  const p_expected_row_version = Number(form.get("expected_row_version") ?? 0);

  const supabase = await supabaseServer();
  const p_idempotency_key = crypto.randomUUID();

  const { error } = await supabase.rpc("update_deal_rpc", {
    p_payload: { id: deal_id, status },
    p_expected_row_version,
    p_idempotency_key,
  });

  if (error) {
    return NextResponse.redirect(
      new URL(`/app/deals/${deal_id}?err=${encodeURIComponent(error.message)}`, req.url),
      { status: 303 }
    );
  }

  return NextResponse.redirect(new URL(`/app/deals/${deal_id}`, req.url), { status: 303 });
}