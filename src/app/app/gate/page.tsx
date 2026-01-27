import { redirect } from "next/navigation";
import { getEntitlementsServer } from "@/lib/entitlements/server";

export default async function GatePage() {
  const ents = await getEntitlementsServer();

  if (!ents.length) redirect("/app/workspace");

  const e = ents[0];
  const status = (e.status ?? "").toLowerCase();
  const tier = (e.tier ?? "").toLowerCase();

  if ((status === "trialing" || status === "active") && tier === "core") {
    redirect("/app/home");
  }

  if (status === "active" && tier === "free") {
    redirect("/app/home");
  }

  redirect("/app/upgrade");
}