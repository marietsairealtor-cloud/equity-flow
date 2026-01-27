export default function HealthPage() {
  return (
    <main style={{ padding: 24 }}>
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>OK</h1>
      <p>Health check page.</p>
      <ul>
        <li><a href="/app/debug/pending-test">/app/debug/pending-test</a></li>
        <li><a href="/app/gate">/app/gate</a></li>
        <li><a href="/app/deals">/app/deals</a></li>
      </ul>
    </main>
  );
}