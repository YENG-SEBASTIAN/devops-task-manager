const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api";

interface TokenPair {
  access: string;
  refresh: string;
}

function getTokens(): TokenPair | null {
  if (typeof window === "undefined") return null;
  const access = localStorage.getItem("access_token");
  const refresh = localStorage.getItem("refresh_token");
  if (!access || !refresh) return null;
  return { access, refresh };
}

export function saveTokens(tokens: TokenPair) {
  localStorage.setItem("access_token", tokens.access);
  localStorage.setItem("refresh_token", tokens.refresh);
}

export function clearTokens() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
}

export function isAuthenticated(): boolean {
  return getTokens() !== null;
}

async function refreshAccessToken(refresh: string): Promise<string> {
  const res = await fetch(`${API_URL}/auth/token/refresh/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh }),
  });
  if (!res.ok) throw new Error("Refresh failed");
  const data = await res.json();
  localStorage.setItem("access_token", data.access);
  return data.access;
}

export async function apiFetch(
  path: string,
  options: RequestInit = {}
): Promise<Response> {
  const tokens = getTokens();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (tokens) {
    headers["Authorization"] = `Bearer ${tokens.access}`;
  }

  let res = await fetch(`${API_URL}${path}`, { ...options, headers });

  if (res.status === 401 && tokens) {
    try {
      const newAccess = await refreshAccessToken(tokens.refresh);
      headers["Authorization"] = `Bearer ${newAccess}`;
      res = await fetch(`${API_URL}${path}`, { ...options, headers });
    } catch {
      clearTokens();
      // eslint-disable-next-line @next/next/no-location-assign-relative-destination
      window.location.href = "/login";
      throw new Error("Session expired");
    }
  }

  return res;
}
