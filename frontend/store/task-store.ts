import { create } from "zustand";
import { apiFetch } from "@/lib/api";

export interface Task {
  id: number;
  title: string;
  description: string;
  completed: boolean;
  due_date: string | null;
  created_at: string;
  updated_at: string;
}

interface TaskState {
  tasks: Task[];
  loading: boolean;
  fetchTasks: () => Promise<void>;
  createTask: (title: string, description?: string, due_date?: string) => Promise<void>;
  toggleTask: (id: number) => Promise<void>;
  deleteTask: (id: number) => Promise<void>;
  updateTask: (id: number, data: Partial<Pick<Task, "title" | "description" | "completed" | "due_date">>) => Promise<void>;
}

export const useTaskStore = create<TaskState>((set) => ({
  tasks: [],
  loading: false,

  fetchTasks: async () => {
    set({ loading: true });
    const res = await apiFetch("/tasks/");
    if (res.ok) {
      const tasks = await res.json();
      set({ tasks, loading: false });
    } else {
      set({ loading: false });
    }
  },

  createTask: async (title, description = "", due_date) => {
    const res = await apiFetch("/tasks/", {
      method: "POST",
      body: JSON.stringify({ title, description, due_date: due_date || null }),
    });
    if (res.ok) {
      const task = await res.json();
      set((state) => ({ tasks: [task, ...state.tasks] }));
    }
  },

  toggleTask: async (id) => {
    const task = useTaskStore.getState().tasks.find((t) => t.id === id);
    if (!task) return;
    const res = await apiFetch(`/tasks/${id}/`, {
      method: "PATCH",
      body: JSON.stringify({ completed: !task.completed }),
    });
    if (res.ok) {
      const updated = await res.json();
      set((state) => ({
        tasks: state.tasks.map((t) => (t.id === id ? updated : t)),
      }));
    }
  },

  deleteTask: async (id) => {
    const res = await apiFetch(`/tasks/${id}/`, { method: "DELETE" });
    if (res.ok) {
      set((state) => ({ tasks: state.tasks.filter((t) => t.id !== id) }));
    }
  },

  updateTask: async (id, data) => {
    const res = await apiFetch(`/tasks/${id}/`, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
    if (res.ok) {
      const updated = await res.json();
      set((state) => ({
        tasks: state.tasks.map((t) => (t.id === id ? updated : t)),
      }));
    }
  },
}));
