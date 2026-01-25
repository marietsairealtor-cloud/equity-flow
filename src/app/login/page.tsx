export default async function LoginPage({ searchParams }: any) {
  const err = String(searchParams?.err ?? "");

  return (
    <div style={{ padding: 24, maxWidth: 420 }}>
      <h1>Login</h1>

      {err && (
        <div style={{ color: "crimson", marginBottom: 12 }}>
          Error: {err}
        </div>
      )}

      <form method="post" action="/auth/login" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <label>
          <div style={{ marginBottom: 4 }}>Email</div>
          <input name="email" type="email" required style={{ width: "100%", padding: 8 }} />
        </label>

        <label>
          <div style={{ marginBottom: 4 }}>Password</div>
          <input name="password" type="password" required style={{ width: "100%", padding: 8 }} />
        </label>

        <button type="submit" style={{ padding: 10, marginTop: 6 }}>Sign in</button>
      </form>
    </div>
  );
}