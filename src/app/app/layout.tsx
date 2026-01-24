export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <section style={{ padding: 24, display: "grid", gap: 16 }}>
      <nav style={{ display: "flex", gap: 12 }}>
        <a href="/app/home">Home</a>
        <a href="/app/deals">Deals</a>
        <a href="/app/workspace">Workspace</a>
        <a href="/app/billing">Billing</a>
      </nav>
      {children}
    </section>
  );
}


