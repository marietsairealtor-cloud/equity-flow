import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const form = await req.formData();
  const status = String(form.get("status") ?? "New");
  const market_area = String(form.get("market_area") ?? "default");

  const supabase = await supabaseServer();
  const p_idempotency_key = crypto.randomUUID();

  const { data, error } = await supabase.rpc("create_deal_rpc", {
    p_payload: { status, market_area },
    p_idempotency_key,
  });

  if (error) {
    if (error.message === "NO_TENANT_SELECTED") {
      return NextResponse.redirect(new URL("/app/workspace?err=NO_TENANT_SELECTED", req.url), { status: 303 });
    }
    return NextResponse.redirect(
      new URL(`/app/deals?err=${encodeURIComponent(error.message)}`, req.url),
      { status: 303 }
    );
  }

  const deal_id = (data as any)?.deal_id ?? "";
  if (!deal_id) {
    return NextResponse.redirect(
      new URL(`/app/deals?err=${encodeURIComponent("CREATE_FAILED_NO_DEAL_ID")}`, req.url),
      { status: 303 }
    );
  }

  return NextResponse.redirect(new URL(`/app/deals/${deal_id}`, req.url), { status: 303 });
}