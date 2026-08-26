"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { useAuthStore } from "@/store/auth-store";
import { Eye, EyeOff } from "lucide-react";

export function AuthScreen({ mode }: { mode: "login" | "register" }) {
  const router = useRouter();
  const { login, register } = useAuthStore();
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const isLogin = mode === "login";

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setLoading(true);

    const data = new FormData(event.currentTarget);
    const username = String(data.get("username") || "").trim();
    const email = String(data.get("email") || "").trim();
    const password = String(data.get("password") || "");

    try {
      if (isLogin) {
        await login(username, password);
      } else {
        await register(username, email, password);
      }
      router.replace("/");
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-white lg:grid lg:grid-cols-[43%_57%]">
      <aside className="hidden flex-col justify-between bg-[#242b43] p-12 text-white lg:flex lg:px-[clamp(3rem,8vw,8rem)]">
        <Brand light />
        <div>
          <p className="text-[10px] font-bold tracking-[.15em] text-violet-200">
            MAKE SPACE FOR WHAT MATTERS
          </p>
          <h1 className="mt-5 text-5xl font-bold leading-none tracking-tight">
            Plan less.
            <br />
            Achieve more.
          </h1>
          <p className="mt-6 max-w-xs text-sm leading-6 text-slate-300">
            A calm, focused home for everything you need to get done.
          </p>
        </div>
        <blockquote className="max-w-xs text-sm leading-6 text-slate-200">
          &ldquo;The simplest way to keep my work and life on track.&rdquo;
          <footer className="mt-3 text-xs text-slate-400">
            &mdash; Maria, Product Designer
          </footer>
        </blockquote>
      </aside>

      <section className="grid min-h-screen place-items-center p-6">
        <div className="w-full max-w-sm">
          <div className="mb-12 lg:hidden">
            <Brand />
          </div>

          <p className="text-[10px] font-bold tracking-[.15em] text-slate-400">
            {isLogin ? "WELCOME BACK" : "START FOR FREE"}
          </p>
          <h1 className="mt-3 text-3xl font-bold tracking-tight text-slate-800">
            {isLogin ? "Welcome back" : "Create your account"}
          </h1>
          <p className="mt-3 text-sm leading-6 text-slate-500">
            {isLogin
              ? "Sign in to see what needs your attention."
              : "Turn plans into progress, one task at a time."}
          </p>

          {error && (
            <div className="mt-4 rounded-lg border border-red-200 bg-red-50 p-3 text-xs text-red-600">
              {error}
            </div>
          )}

          <form onSubmit={submit} className="mt-8 grid gap-5">
            <Field
              label="Username"
              name="username"
              placeholder="alex.morgan"
              autoComplete="username"
            />
            {!isLogin && (
              <Field
                label="Email address"
                name="email"
                type="email"
                placeholder="you@example.com"
                autoComplete="email"
              />
            )}
            <div className="relative">
              <Field
                label="Password"
                name="password"
                type={showPassword ? "text" : "password"}
                placeholder="At least 8 characters"
                minLength={8}
                autoComplete={isLogin ? "current-password" : "new-password"}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-[38px] text-slate-400 hover:text-slate-600"
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>

            {isLogin && (
              <div className="flex justify-between text-xs">
                <label className="flex items-center gap-2 text-slate-500">
                  <input type="checkbox" /> Remember me
                </label>
                <a className="font-bold text-[#7657f8]" href="#">
                  Forgot password?
                </a>
              </div>
            )}

            <button
              disabled={loading}
              className="rounded-lg bg-[#7657f8] py-3 text-sm font-bold text-white transition-opacity hover:opacity-90 disabled:opacity-50"
            >
              {loading
                ? "Please wait..."
                : isLogin
                  ? "Sign in"
                  : "Create account"}
            </button>
          </form>

          <p className="mt-6 text-center text-sm text-slate-500">
            {isLogin ? "New to Taskflow?" : "Already have an account?"}{" "}
            <Link
              className="font-bold text-[#7657f8]"
              href={isLogin ? "/register" : "/login"}
            >
              {isLogin ? "Create an account" : "Sign in"}
            </Link>
          </p>
        </div>
      </section>
    </main>
  );
}

function Field({
  label,
  name,
  type = "text",
  placeholder,
  minLength,
  autoComplete,
}: {
  label: string;
  name: string;
  type?: string;
  placeholder: string;
  minLength?: number;
  autoComplete?: string;
}) {
  return (
    <label className="grid gap-2 text-xs font-bold text-slate-600">
      {label}
      <input
        required
        name={name}
        type={type}
        minLength={minLength}
        placeholder={placeholder}
        autoComplete={autoComplete}
        className="rounded-lg border border-slate-200 p-3 text-sm font-normal outline-violet-500"
      />
    </label>
  );
}

function Brand({ light = false }: { light?: boolean }) {
  return (
    <Link
      href="/"
      className={`inline-flex items-center gap-2 text-xl font-bold tracking-tight ${light ? "text-white" : "text-[#242a3b]"}`}
    >
      <span className="grid h-7 w-7 place-items-center rounded-lg bg-[#7657f8] text-base text-white">
        ✓
      </span>
      Taskflow
    </Link>
  );
}
