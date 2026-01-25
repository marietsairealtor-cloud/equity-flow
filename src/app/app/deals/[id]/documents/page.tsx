import { supabaseServer } from "@/lib/supabase/server";
import DocumentsClient from "./ui";

type Params = { id: string };

export default async function DealDocumentsPage({ params }: { params: Promise<Params> }) {
  const { id } = await params;
  const supabase = await supabaseServer();

  const ent = await supabase.rpc("get_entitlements");
  const tenantId = (ent.data?.[0]?.tenant_id as string | null) ?? null;

  const docs = await supabase
    .from("documents")
    .select("id, storage_path, file_name, mime_type, size_bytes, created_at")
    .eq("deal_id", id)
    .order("created_at", { ascending: false });

  return (
    <DocumentsClient
      dealId={id}
      tenantId={tenantId ?? ""}
      initialDocs={(docs.data ?? []) as any[]}
    />
  );
}