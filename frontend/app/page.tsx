import { ProtectedRoute } from "@/components/protected-route";
import { TaskDashboard } from "@/components/task-dashboard";

export default function Home() {
  return (
    <ProtectedRoute>
      <TaskDashboard />
    </ProtectedRoute>
  );
}
