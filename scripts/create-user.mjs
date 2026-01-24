import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const service = process.env.SUPABASE_SERVICE_ROLE_KEY;

const email = process.argv[2];
const password = process.argv[3];

if (!url || !service) throw new Error("Missing env vars in .env.local");
if (!email || !password) throw new Error("Usage: node --env-file=.env.local scripts/create-user.mjs email password");

const supabase = createClient(url, service, { auth: { persistSession: false } });

const { data, error } = await supabase.auth.admin.createUser({
  email,
  password,
  email_confirm: true,
});

console.log(JSON.stringify({ ok: !error, error: error?.message ?? null, user_id: data?.user?.id ?? null }, null, 2));
