import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

function supabaseServer() {
  const cookieStore = cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
        set(name: string, value: string, options: any) {
          cookieStore.set({ name, value, ...options });
        },
        remove(name: string, options: any) {
          cookieStore.set({ name, value: "", ...options, maxAge: 0 });
        },
      },
    }
  );
}

export async function POST(req: Request) {
  const supabase = supabaseServer();

  const { data: authData, error: authErr } = await supabase.auth.getUser();
  if (authErr || !authData?.user) {
    return NextResponse.json({ ok: false, error: "NOT_AUTHENTICATED" }, { status: 401 });
  }

  let body: any = null;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "BAD_JSON" }, { status: 400 });
  }

  const tenant_id = (body?.tenant_id ?? "").toString();
  if (!tenant_id) {
    return NextResponse.json({ ok: false, error: "MISSING_TENANT_ID" }, { status: 400 });
  }

  const { error } = await supabase.rpc("set_current_tenant_id_rpc", { p_tenant_id: tenant_id });
  if (error) {
    return NextResponse.json(
      { ok: false, error: "RPC_FAILED", detail: error.message },
      { status: 400 }
    );
  }

  return NextResponse.json({ ok: true }, { status: 200 });
}
