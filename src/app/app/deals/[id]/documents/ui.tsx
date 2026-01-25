"use client";

import { useMemo, useState } from "react";
import { createClient } from "@supabase/supabase-js";

type DocRow = {
  id: string;
  storage_path: string;
  file_name: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  created_at: string;
};

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

const UI = {
  page: { padding: 16, maxWidth: 900, color: "#eee" as const },
  card: { padding: "12px 12px", borderRadius: 12, border: "1px solid #2a2a2a", background: "#0f0f0f" as const },
  subtle: { fontSize: 13, color: "#bbb" as const },
  h1: { fontSize: 20, fontWeight: 800, color: "#fff" as const, margin: 0 },
  link: { fontSize: 13, color: "#9cc9ff" as const, textDecoration: "none" as const },
  input: {
    color: "#eee",
    background: "#121212",
    border: "1px solid #3a3a3a",
    borderRadius: 10,
    padding: "8px 10px",
  } as const,
  btn: {
    padding: "8px 10px",
    borderRadius: 10,
    border: "1px solid #3a3a3a",
    background: "#1a1a1a",
    color: "#eee",
  } as const,
  err: {
    marginTop: 10,
    padding: "10px 12px",
    borderRadius: 10,
    border: "1px solid #7a2a2a",
    background: "#1a0f0f",
    color: "#ffd0d0",
    fontSize: 12,
    whiteSpace: "pre-wrap" as const,
  },
};

function prettyBytes(n?: number | null) {
  if (!n || n < 0) return "-";
  const units = ["B", "KB", "MB", "GB"];
  let v = n;
  let i = 0;
  while (v >= 1024 && i < units.length - 1) { v = v / 1024; i++; }
  return `${v.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

export default function DocumentsUI(props: {
  tenantId: string | null;
  dealId: string;
  initialDocs: DocRow[];
}) {
  const [docs, setDocs] = useState<DocRow[]>(props.initialDocs ?? []);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const [file, setFile] = useState<File | null>(null);

  const hasDocs = useMemo(() => (docs?.length ?? 0) > 0, [docs]);

  async function refresh() {
    const r = await supabase
      .from("documents")
      .select("id,storage_path,file_name,mime_type,size_bytes,created_at")
      .eq("deal_id", props.dealId)
      .order("created_at", { ascending: false });

    if (r.error) throw new Error(r.error.message);
    setDocs((r.data ?? []) as DocRow[]);
  }

  async function uploadSelected() {
    setErr("");
    if (!file) { setErr("FILE_REQUIRED"); return; }

    setBusy(true);
    try {
      // Always re-check tenant on client via SECURITY DEFINER RPC
      const t = await supabase.rpc("get_current_tenant_id");
      const tenantId = (t.data as string | null) ?? props.tenantId;
      if (!tenantId) throw new Error("NO_TENANT_SELECTED");

      const safeName = file.name.replace(/[^\w.\-]+/g, "_");
      const storage_path = `${tenantId}/${props.dealId}/${Date.now()}_${safeName}`;

      const up = await supabase.storage.from("deal-files").upload(storage_path, file, {
        upsert: false,
        contentType: file.type || undefined,
      });
      if (up.error) throw new Error(up.error.message);

      const doc = await supabase.rpc("create_document_after_upload", {
        p_deal_id: props.dealId,
        p_storage_path: storage_path,
        p_file_name: file.name,
        p_mime_type: file.type || null,
        p_size_bytes: file.size,
      });
      if (doc.error) throw new Error(doc.error.message);

      await refresh();
      setFile(null);
      const el = document.getElementById("docFile") as HTMLInputElement | null;
      if (el) el.value = "";
    } catch (e: any) {
      setErr(e?.message ?? "UPLOAD_FAILED");
    } finally {
      setBusy(false);
    }
  }

  async function downloadSigned(storage_path: string) {
    setErr("");
    try {
      const s = await supabase.storage.from("deal-files").createSignedUrl(storage_path, 60);
      if (s.error) throw new Error(s.error.message);
      window.open(s.data.signedUrl, "_blank");
    } catch (e: any) {
      setErr(e?.message ?? "SIGNED_URL_FAILED");
    }
  }

  return (
    <div style={UI.page}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <h1 style={UI.h1}>Documents</h1>
        <a href={`/app/deals/${props.dealId}`} style={UI.link}>Back to Deal</a>
      </div>

      <div style={{ marginTop: 12, ...UI.card }}>
        <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
          <input
            id="docFile"
            type="file"
            disabled={busy}
            style={UI.input}
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
          />
          <button onClick={uploadSelected} disabled={busy || !file} style={UI.btn}>
            {busy ? "Uploading..." : "Upload"}
          </button>
          <div style={UI.subtle}>Storage policies still required (dashboard) for real uploads.</div>
        </div>
        {err ? <div style={UI.err}>{err}</div> : null}
      </div>

      <div style={{ marginTop: 12, display: "grid", gap: 8 }}>
        {!hasDocs ? (
          <div style={UI.subtle}>No documents.</div>
        ) : (
          docs.map((d) => (
            <div key={d.id} style={UI.card}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center" }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 800, color: "#fff" }}>{d.file_name ?? d.storage_path}</div>
                  <div style={UI.subtle}>
                    {prettyBytes(d.size_bytes)} • {d.mime_type ?? "-"} • {d.created_at}
                  </div>
                </div>
                <button style={UI.btn} onClick={() => downloadSigned(d.storage_path)} disabled={busy}>
                  Download
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}