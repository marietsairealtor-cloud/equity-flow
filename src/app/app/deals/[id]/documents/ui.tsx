"use client";

import { useMemo, useState } from "react";
import { supabaseBrowser } from "@/lib/supabase/client";

type DocRow = {
  id: string;
  storage_path: string;
  file_name: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  created_at: string;
};

export default function DocumentsClient(props: { dealId: string; tenantId: string; initialDocs: DocRow[] }) {
  const supabase = useMemo(() => supabaseBrowser(), []);
  const [docs, setDocs] = useState<DocRow[]>(props.initialDocs ?? []);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string>("");

  async function onUpload(e: React.ChangeEvent<HTMLInputElement>) {
    setErr("");
    const f = e.target.files?.[0];
    if (!f) return;
    if (!props.tenantId) { setErr("NO_TENANT_SELECTED"); return; }

    setBusy(true);
    try {
      const safeName = f.name.replaceAll("/", "_");
      const key = `${props.tenantId}/${props.dealId}/${crypto.randomUUID()}_${safeName}`;

      const up = await supabase.storage.from("deal-files").upload(key, f, {
        upsert: false,
        contentType: f.type || undefined,
      });

      if (up.error) throw new Error(up.error.message);

      const rpc = await supabase.rpc("create_document_after_upload", {
        p_deal_id: props.dealId,
        p_storage_path: key,
        p_file_name: f.name,
        p_mime_type: f.type || null,
        p_size_bytes: f.size,
      });

      if (rpc.error) throw new Error(rpc.error.message);

      const refreshed = await supabase
        .from("documents")
        .select("id, storage_path, file_name, mime_type, size_bytes, created_at")
        .eq("deal_id", props.dealId)
        .order("created_at", { ascending: false });

      if (refreshed.error) throw new Error(refreshed.error.message);
      setDocs((refreshed.data ?? []) as any);
    } catch (e: any) {
      setErr(e?.message ?? "UPLOAD_FAILED");
    } finally {
      setBusy(false);
      e.target.value = "";
    }
  }

  return (
    <div style={{ padding: 16, maxWidth: 900 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <h1 style={{ fontSize: 20, fontWeight: 800, margin: 0 }}>Documents</h1>
        <a href={`/app/deals/${props.dealId}`} style={{ fontSize: 13, color: "#444" }}>Back to Deal</a>
      </div>

      <div style={{ marginTop: 12, display: "flex", gap: 10, alignItems: "center" }}>
        <input type="file" onChange={onUpload} disabled={busy} />
        {busy ? <div style={{ fontSize: 13 }}>Uploading...</div> : null}
      </div>

      {err ? (
        <div style={{ marginTop: 10, padding: "10px 12px", borderRadius: 10, border: "1px solid #f0c2c2", background: "#fff7f7", fontSize: 12, whiteSpace: "pre-wrap" }}>
          {err}
        </div>
      ) : null}

      <div style={{ marginTop: 16, display: "grid", gap: 8 }}>
        {docs.length === 0 ? (
          <div style={{ fontSize: 13, color: "#444" }}>No documents yet.</div>
        ) : (
          docs.map((d) => (
            <div key={d.id} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #eee" }}>
              <div style={{ fontWeight: 700, fontSize: 13 }}>{d.file_name ?? d.storage_path.split("/").slice(-1)[0]}</div>
              <div style={{ fontSize: 12, color: "#444" }}>
                {d.mime_type ?? "-"} • {d.size_bytes ?? 0} bytes • {d.created_at}
              </div>
              <div style={{ marginTop: 6 }}>
                <a
                  href="#"
                  onClick={async (ev) => {
                    ev.preventDefault();
                    const s = await supabase.storage.from("deal-files").createSignedUrl(d.storage_path, 60);
                    if (s.error) { setErr(s.error.message); return; }
                    window.open(s.data.signedUrl, "_blank");
                  }}
                  style={{ fontSize: 13 }}
                >
                  Download (signed)
                </a>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}