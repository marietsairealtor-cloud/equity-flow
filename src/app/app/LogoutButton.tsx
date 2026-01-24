"use client";

export default function LogoutButton() {
  async function logout() {
    await fetch("/auth/logout", { method: "POST" });
    window.location.href = "/login";
  }

  return <button onClick={logout}>Logout</button>;
}
