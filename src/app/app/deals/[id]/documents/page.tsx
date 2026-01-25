import { supabaseServer } from "@/lib/supabase/server";
import DocumentsUI from "./ui";

type DocRow = {
  id: string;
  storage_path: string;
  file_name: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  created_at: string;
};

export default async function DealDocumentsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await supabaseServer();

  const me = await supabase.auth.getUser();
  const userId = me.data.user?.id ?? null;

  let tenantId: string | null = null;
  if (userId) {
    const prof = await supabase
      .from("user_profiles")
      .select("current_tenant_id")
      .eq("user_id", userId)
      .maybeSingle();
    tenantId = (prof.data?.current_tenant_id as string | null) ?? null;
  }

  const docs = await supabase
    .from("documents")
    .select("id,storage_path,file_name,mime_type,size_bytes,created_at")
    .eq("deal_id", id)
    .order("created_at", { ascending: false });

  return <DocumentsUI tenantId={tenantId} dealId={id} initialDocs={(docs.data ?? []) as DocRow[]} />;
}