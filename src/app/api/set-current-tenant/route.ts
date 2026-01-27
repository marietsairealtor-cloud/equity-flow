import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

function supabaseServer() {
  const cookieStore = cookies();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
  return createServerClient(url, anon, {
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
  });
}

export async function POST(req: Request) {
  const supabase = supabaseServer();
  const body = await req.json().catch(() => ({} as any));
  const tenant_id = body?.tenant_id;

  if (!tenant_id) {
    return NextResponse.json({ error: "MISSING_TENANT_ID" }, { status: 400 });
  }

  const { data, error } = await supabase.rpc("set_current_tenant", { p_tenant_id: tenant_id });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ ok: true, tenant_id: data }, { status: 200 });
}
