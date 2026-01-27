import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

function parseCookieHeader(header: string | null): { name: string; value: string }[] {
  if (!header) return [];
  return header
    .split(";")
    .map((p) => p.trim())
    .filter(Boolean)
    .map((kv) => {
      const eq = kv.indexOf("=");
      if (eq === -1) return { name: kv, value: "" };
      return { name: kv.slice(0, eq), value: decodeURIComponent(kv.slice(eq + 1)) };
    });
}

function supabaseFromRequest(req: Request) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  const authHeader = req.headers.get("authorization") || "";

  // Support Bearer token callers too
  if (authHeader.toLowerCase().startsWith("bearer ")) {
    return createClient(url, key, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });
  }

  // Default: browser cookies
  const cookiePairs = parseCookieHeader(req.headers.get("cookie"));
  return createServerClient(url, key, {
    cookies: {
      getAll() { return cookiePairs; },
      setAll() { /* no-op */ },
    },
  });
}

export async function GET(req: Request) {
  try {
    const url = new URL(req.url);
    const deal_id = url.searchParams.get("id") || "";
    if (!deal_id) return NextResponse.json({ error: "MISSING_ID" }, { status: 400 });

    const supabase = supabaseFromRequest(req);
    const { data, error } = await supabase.rpc("get_deal", { deal_id });

    if (error) {
      return NextResponse.json(
        { error: error.message, code: error.code, details: error.details, hint: error.hint },
        { status: 400 }
      );
    }

    return NextResponse.json({ ok: true, data }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: "UNHANDLED_EXCEPTION", message: e?.message ?? String(e) }, { status: 500 });
  }
}
