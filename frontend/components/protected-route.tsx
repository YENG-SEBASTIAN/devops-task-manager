"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth-store";
import { isAuthenticated } from "@/lib/api";

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { initialized, fetchUser, user } = useAuthStore();

  useEffect(() => {
    if (!initialized) {
      fetchUser();
    }
  }, [initialized, fetchUser]);

  useEffect(() => {
    if (initialized && !user && !isAuthenticated()) {
      router.replace("/login");
    }
  }, [initialized, user, router]);

  if (!initialized) {
    return (
      <div className="grid min-h-screen place-items-center bg-[#f7f8fc]">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#7657f8] border-t-transparent" />
      </div>
    );
  }

  if (!user && !isAuthenticated()) return null;

  return <>{children}</>;
}
