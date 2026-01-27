export default function PendingTestPage() {
  return (
    <main style={{ padding: 24, maxWidth: 720 }}>
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>Pending-user flow test</h1>

      <ol style={{ marginTop: 12, lineHeight: 1.6 }}>
        <li>Click the button. You should see a JSON response with before/update/after.</li>
        <li>Then open <code>/app/gate</code> to confirm redirect to <code>/app/upgrade</code>.</li>
      </ol>

      <form action="/api/debug/reset-pending" method="post" style={{ marginTop: 16 }}>
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
          POST /api/debug/reset-pending (force pending)
        </button>
      </form>

      <div style={{ marginTop: 16 }}>
        <a href="/app/gate">Go to /app/gate</a>{" | "}
        <a href="/app/debug/tenant-status">/app/debug/tenant-status</a>
      </div>
    </main>
  );
}