import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

export async function supabaseServer() {
  const cookieStore = cookies();

  // Next 16 cookies() supports getAll(), but on some runtimes it may not.
  // We only need reads here; writes are no-op.
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          // @ts-ignore
          return cookieStore.getAll ? cookieStore.getAll() : [];
        },
        setAll() {
          // no-op
        },
      },
    }
  );
}
