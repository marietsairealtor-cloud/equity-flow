import { redirect } from "next/navigation";

export default function ResetPendingRedirectPage() {
  redirect("/api/debug/reset-pending");
}