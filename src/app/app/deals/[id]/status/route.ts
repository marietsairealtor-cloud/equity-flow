import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";

type Body = { status: string; expected_row_version: number };

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

async function readBody(req: Request): Promise<Body> {
  const ct = (req.headers.get("content-type") || "").toLowerCase();

  // JSON fetch
  if (ct.includes("application/json")) {
    const j = (await req.json()) as any;
    const status = j?.status ?? j?.p_status;
    const ev = j?.expected_row_version ?? j?.p_expected_row_version;
    const expected_row_version = typeof ev === "number" ? ev : parseInt(String(ev ?? ""), 10);
    return { status: String(status ?? ""), expected_row_version };
  }

  // HTML form POST (application/x-www-form-urlencoded or multipart/form-data)
  const fd = await req.formData();
  const status = (fd.get("status") ?? fd.get("p_status") ?? "").toString();
  const ev = (fd.get("expected_row_version") ?? fd.get("p_expected_row_version") ?? "").toString();
  const expected_row_version = parseInt(ev, 10);
  return { status, expected_row_version };
}

export async function POST(req: Request, ctx: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await ctx.params;
    const body = await readBody(req);

    if (!id) return NextResponse.json({ error: "MISSING_DEAL_ID" }, { status: 400 });
    if (!body?.status) return NextResponse.json({ error: "MISSING_STATUS" }, { status: 400 });
    if (!Number.isFinite(body.expected_row_version)) {
      return NextResponse.json({ error: "MISSING_EXPECTED_ROW_VERSION" }, { status: 400 });
    }

    const supabase = supabaseFromRequest(req);

    const { data, error } = await supabase.rpc("update_deal_status_rpc", {
      p_deal_id: id,
      p_expected_row_version: body.expected_row_version,
      p_status: body.status,
    });

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
