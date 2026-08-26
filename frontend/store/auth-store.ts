import { create } from "zustand";
import {
  apiFetch,
  saveTokens,
  clearTokens,
  isAuthenticated as checkAuth,
} from "@/lib/api";

interface User {
  id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
}

interface AuthState {
  user: User | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (
    username: string,
    email: string,
    password: string
  ) => Promise<void>;
  logout: () => void;
  fetchUser: () => Promise<void>;
  initialized: boolean;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  loading: false,
  initialized: false,

  login: async (username, password) => {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api"}/auth/token/`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      }
    );
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.detail || "Invalid credentials");
    }
    const tokens = await res.json();
    saveTokens(tokens);
    await useAuthStore.getState().fetchUser();
  },

  register: async (username, email, password) => {
    const res = await apiFetch("/auth/register/", {
      method: "POST",
      body: JSON.stringify({ username, email, password }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      const msg = Object.values(data).flat().join(" ");
      throw new Error(msg || "Registration failed");
    }
    await useAuthStore.getState().login(username, password);
  },

  logout: () => {
    clearTokens();
    set({ user: null });
  },

  fetchUser: async () => {
    if (!checkAuth()) {
      set({ user: null, initialized: true });
      return;
    }
    try {
      const res = await apiFetch("/auth/me/");
      if (!res.ok) throw new Error("Failed to fetch user");
      const user = await res.json();
      set({ user, initialized: true });
    } catch {
      clearTokens();
      set({ user: null, initialized: true });
    }
  },
}));
