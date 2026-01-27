export default function CreatePendingWorkspacePage() {
  return (
    <main style={{ padding: 24, maxWidth: 760 }}>
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>Create pending workspace (debug)</h1>
      <p style={{ marginTop: 8 }}>
        This creates a brand-new workspace (you as owner), forces subscription_status=pending, sets current tenant,
        then redirects to <code>/app/gate</code>.
      </p>

      <form action="/api/debug/create-pending-workspace" method="post" style={{ marginTop: 16 }}>
        <button
          type="submit"
          style={{
            padding: "10px 14px",
            borderRadius: 8,
            border: "1px solid #ccc",
            cursor: "pointer",
            fontWeight: 600,
          }}
        >
          Create + force pending + go to /app/gate
        </button>
      </form>

      <div style={{ marginTop: 16 }}>
        <a href="/app/debug/tenant-status">/app/debug/tenant-status</a>
      </div>
    </main>
  );
}