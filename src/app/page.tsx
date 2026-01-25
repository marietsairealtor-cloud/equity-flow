import Link from "next/link";

export default function HomePage() {
  return (
    <div style={{ padding: 24 }}>
      <h1>Equity Flow</h1>
      <div style={{ marginTop: 12, display: "flex", gap: 12 }}>
        <Link href="/login">Login</Link>
        <Link href="/app/gate">Open App</Link>
      </div>
    </div>
  );
}