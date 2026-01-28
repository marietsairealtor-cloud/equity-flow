export default async function LoginPage(props: any) {
  const sp = await props.searchParams;
  const err = String(sp?.err ?? "");

  return (
    <div style={{ padding: 24, maxWidth: 420 }}>
      <h1>Login</h1>
      {err ? (
        <p style={{ marginTop: 12, whiteSpace: 'pre-wrap' }}>{err}</p>
      ) : null}
      <p style={{ marginTop: 12 }}>Go to <code>/auth/login</code>.</p>
    </div>
  );
}