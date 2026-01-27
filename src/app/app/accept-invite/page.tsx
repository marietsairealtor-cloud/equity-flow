import { redirect } from "next/navigation";
import { supabaseServer } from "@/lib/supabase/server";
import AcceptInviteClient from "./accept-invite-client";

export default async function AcceptInvitePage() {
  const supabase = await supabaseServer();

  const { data: userRes } = await supabase.auth.getUser();
  if (!userRes?.user) redirect("/login");

  const { data: invites, error } = await supabase.rpc("get_my_pending_invites_rpc");
  return <AcceptInviteClient invites={invites ?? []} error={error?.message ?? null} />;
}
