export const dynamic = "force-dynamic";

type Props = { searchParams?: { err?: string } };

export default function LoginPage({ searchParams }: Props) {
  const err = typeof searchParams?.err === "string" ? searchParams.err : "";

  return (
    <main style={{ maxWidth: 420, margin: "64px auto", padding: 16, fontFamily: "system-ui" }}>
      <h1 style={{ fontSize: 22, marginBottom: 12 }}>Login</h1>

      {err ? (
        <div style={{ background: "#fee", border: "1px solid #f99", padding: 10, borderRadius: 8, marginBottom: 12 }}>
          {err}
        </div>
      ) : null}

      <form method="POST" action="/auth/login/submit" style={{ display: "grid", gap: 10 }}>
        <label style={{ display: "grid", gap: 6 }}>
          <span>Email</span>
          <input name="email" type="email" required style={{ padding: 10, borderRadius: 8, border: "1px solid #ccc" }} />
        </label>

        <label style={{ display: "grid", gap: 6 }}>
          <span>Password</span>
          <input name="password" type="password" required style={{ padding: 10, borderRadius: 8, border: "1px solid #ccc" }} />
        </label>

        <button type="submit" style={{ padding: 10, borderRadius: 8, border: "1px solid #333", cursor: "pointer" }}>
          Sign in
        </button>
      </form>
    </main>
  );
}