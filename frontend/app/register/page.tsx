"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthScreen } from "@/components/auth-screen";
import { useAuthStore } from "@/store/auth-store";
import { isAuthenticated } from "@/lib/api";

export default function RegisterPage() {
  const router = useRouter();
  const { user, fetchUser, initialized } = useAuthStore();

  useEffect(() => {
    if (!initialized) fetchUser();
  }, [initialized, fetchUser]);

  useEffect(() => {
    if (initialized && (user || isAuthenticated())) {
      router.replace("/");
    }
  }, [initialized, user, router]);

  if (initialized && !user && !isAuthenticated()) {
    return <AuthScreen mode="register" />;
  }

  return null;
}
