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

  if (authHeader.toLowerCase().startsWith("bearer ")) {
    return createClient(url, key, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });
  }

  const cookiePairs = parseCookieHeader(req.headers.get("cookie"));

  return createServerClient(url, key, {
    cookies: {
      getAll() {
        return cookiePairs;
      },
      setAll() {
        // no-op
      },
    },
  });
}

export async function GET(req: Request) {
  const supabase = supabaseFromRequest(req);
  const dbg = await supabase.rpc("debug_context_rpc");
  return NextResponse.json(
    { ok: !dbg.error, data: dbg.data ?? null, error: dbg.error ?? null },
    { status: dbg.error ? 400 : 200 }
  );
}
