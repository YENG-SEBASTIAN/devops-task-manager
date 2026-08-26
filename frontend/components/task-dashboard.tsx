"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Search,
  Plus,
  CheckCircle2,
  Circle,
  Clock,
  Trash2,
  LogOut,
  ListTodo,
  Loader2,
  X,
  CalendarDays,
} from "lucide-react";
import { useTaskStore, Task } from "@/store/task-store";
import { useAuthStore } from "@/store/auth-store";

type Filter = "all" | "active" | "completed";

export function TaskDashboard() {
  const router = useRouter();
  const { tasks, loading, fetchTasks, createTask, toggleTask, deleteTask } =
    useTaskStore();
  const { user, logout } = useAuthStore();
  const [filter, setFilter] = useState<Filter>("all");
  const [search, setSearch] = useState("");
  const [isComposerOpen, setIsComposerOpen] = useState(false);

  useEffect(() => {
    fetchTasks();
  }, [fetchTasks]);

  const openTasks = tasks.filter((t) => !t.completed).length;
  const completedTasks = tasks.length - openTasks;

  const visibleTasks = useMemo(() => {
    return tasks.filter((task) => {
      const matchesFilter =
        filter === "all" ||
        (filter === "active" && !task.completed) ||
        (filter === "completed" && task.completed);
      const matchesSearch = task.title
        .toLowerCase()
        .includes(search.toLowerCase());
      return matchesFilter && matchesSearch;
    });
  }, [filter, search, tasks]);

  function handleAddTask(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const title = String(data.get("title") || "").trim();
    const description = String(data.get("description") || "").trim();
    const due_date = String(data.get("due_date") || "");
    if (!title) return;
    createTask(title, description, due_date || undefined);
    setIsComposerOpen(false);
  }

  function handleLogout() {
    logout();
    router.replace("/login");
  }

  return (
    <main className="min-h-screen bg-[#f7f8fc] text-[#242a3b] lg:grid lg:grid-cols-[250px_1fr]">
      <aside className="hidden min-h-screen flex-col bg-[#22293d] p-5 text-[#b7bfd2] lg:flex">
        <Brand />
        <button
          onClick={() => setIsComposerOpen(true)}
          className="mt-10 flex items-center justify-center gap-2 rounded-lg bg-[#7657f8] py-3 text-sm font-bold text-white shadow-lg shadow-violet-950/20 transition-opacity hover:opacity-90"
        >
          <Plus size={16} /> Add task
        </button>

        <nav className="mt-7 grid gap-1">
          {(["all", "active", "completed"] as Filter[]).map((item) => (
            <button
              key={item}
              onClick={() => setFilter(item)}
              className={`flex justify-between rounded-lg px-3 py-2.5 text-left text-sm capitalize ${
                filter === item ? "bg-white/10 text-white" : "hover:bg-white/5"
              }`}
            >
              <span>
                {item === "all" ? "All tasks" : item}
              </span>
              <span className="text-xs opacity-60">
                {item === "all"
                  ? tasks.length
                  : item === "active"
                    ? openTasks
                    : completedTasks}
              </span>
            </button>
          ))}
        </nav>

        <div className="mt-auto border-t border-white/10 pt-5">
          <div className="flex items-center gap-3">
            <div className="grid h-8 w-8 place-items-center rounded-full bg-[#ddd4fa] text-[10px] font-bold text-[#4d3a91]">
              {user?.username?.slice(0, 2).toUpperCase() || "??"}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-bold text-white">
                {user?.username || "User"}
              </p>
              <p className="truncate text-xs text-[#8790a5]">
                {user?.email || ""}
              </p>
            </div>
            <button
              onClick={handleLogout}
              className="text-[#8790a5] transition-colors hover:text-white"
              title="Sign out"
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      <section className="min-w-0">
        <header className="flex h-17 items-center justify-between border-b border-slate-200 bg-white px-5 lg:h-20 lg:px-12">
          <div className="lg:hidden">
            <Brand />
          </div>

          <div className="relative hidden w-full max-w-xs lg:block">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
            />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search tasks..."
              className="w-full rounded-lg border border-slate-200 bg-slate-50 py-2 pl-10 pr-4 text-sm outline-none focus:border-[#7657f8] focus:ring-1 focus:ring-[#7657f8]"
            />
            {search && (
              <button
                onClick={() => setSearch("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X size={14} />
              </button>
            )}
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700 lg:hidden"
            >
              <LogOut size={16} />
            </button>
          </div>
        </header>

        <div className="mx-auto max-w-5xl px-5 py-10 lg:px-12 lg:py-13">
          <div className="flex items-end justify-between gap-4">
            <div>
              <h1 className="text-3xl font-bold tracking-tight lg:text-[34px]">
                {filter === "all"
                  ? `Welcome back, ${user?.username || "there"}`
                  : `${filter[0].toUpperCase()}${filter.slice(1)} tasks`}
              </h1>
              <p className="mt-2 text-sm text-slate-500">
                {loading ? (
                  <span className="inline-flex items-center gap-1">
                    <Loader2 size={14} className="animate-spin" /> Loading
                    tasks...
                  </span>
                ) : (
                  <>
                    You have {openTasks} open{" "}
                    {openTasks === 1 ? "task" : "tasks"}.
                  </>
                )}
              </p>
            </div>
            <button
              onClick={() => setIsComposerOpen(true)}
              className="hidden items-center gap-2 rounded-lg bg-[#7657f8] px-4 py-3 text-sm font-bold text-white transition-opacity hover:opacity-90 lg:flex"
            >
              <Plus size={16} /> Add task
            </button>
          </div>

          <section className="mt-8 grid gap-3 sm:grid-cols-3">
            <Stat
              icon={<ListTodo size={18} className="text-[#7657f8]" />}
              label="OPEN TASKS"
              value={String(openTasks)}
            />
            <Stat
              icon={<CheckCircle2 size={18} className="text-emerald-500" />}
              label="COMPLETED"
              value={String(completedTasks)}
            />
            <Stat
              icon={<Clock size={18} className="text-orange-400" />}
              label="TOTAL"
              value={String(tasks.length)}
            />
          </section>

          <section className="mt-10">
            <div className="mb-4 flex items-end justify-between">
              <div>
                <h2 className="text-lg font-bold">Your tasks</h2>
                <p className="text-xs text-slate-400">
                  {visibleTasks.length} {visibleTasks.length === 1 ? "task" : "tasks"}
                </p>
              </div>
            </div>

            <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
              {loading && tasks.length === 0 ? (
                <div className="flex items-center justify-center gap-2 p-10 text-sm text-slate-400">
                  <Loader2 size={16} className="animate-spin" /> Loading
                  tasks...
                </div>
              ) : visibleTasks.length === 0 ? (
                <p className="p-10 text-center text-sm text-slate-400">
                  {search
                    ? `No tasks matching "${search}"`
                    : "No tasks yet. Create one to get started."}
                </p>
              ) : (
                visibleTasks.map((task) => (
                  <TaskRow
                    key={task.id}
                    task={task}
                    onToggle={toggleTask}
                    onDelete={deleteTask}
                  />
                ))
              )}
            </div>
          </section>
        </div>
      </section>

      {isComposerOpen && (
        <div className="fixed inset-0 z-10 grid place-items-center bg-slate-950/40 p-5">
          <form
            onSubmit={handleAddTask}
            className="w-full max-w-md rounded-2xl bg-white p-7 shadow-2xl"
          >
            <div className="flex justify-between">
              <div>
                <p className="text-[10px] font-bold tracking-[.14em] text-slate-400">
                  NEW TASK
                </p>
                <h2 className="mt-2 text-xl font-bold">What needs doing?</h2>
              </div>
              <button
                type="button"
                onClick={() => setIsComposerOpen(false)}
                className="grid h-8 w-8 place-items-center rounded-lg text-2xl text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600"
              >
                ×
              </button>
            </div>

            <label className="mt-6 block text-xs font-bold text-slate-600">
              Task name
              <input
                autoFocus
                required
                name="title"
                className="mt-2 w-full rounded-lg border border-slate-200 p-3 text-sm outline-violet-500"
                placeholder="Prepare the demo"
              />
            </label>

            <label className="mt-4 block text-xs font-bold text-slate-600">
              Description
              <textarea
                name="description"
                rows={3}
                className="mt-2 w-full resize-none rounded-lg border border-slate-200 p-3 text-sm outline-violet-500"
                placeholder="Optional details..."
              />
            </label>

            <label className="mt-4 block text-xs font-bold text-slate-600">
              Due date
              <input
                type="date"
                name="due_date"
                className="mt-2 w-full rounded-lg border border-slate-200 p-3 text-sm outline-violet-500"
              />
            </label>

            <div className="mt-7 flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setIsComposerOpen(false)}
                className="rounded-lg bg-slate-100 px-4 py-2.5 text-sm font-bold text-slate-600"
              >
                Cancel
              </button>
              <button className="rounded-lg bg-[#7657f8] px-4 py-2.5 text-sm font-bold text-white transition-opacity hover:opacity-90">
                Create task
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="fixed bottom-5 left-5 right-5 z-20 lg:hidden">
        <div className="relative">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search tasks..."
            className="w-full rounded-xl border border-slate-200 bg-white py-3 pl-10 pr-10 text-sm shadow-lg outline-none focus:border-[#7657f8] focus:ring-1 focus:ring-[#7657f8]"
          />
          {search && (
            <button
              onClick={() => setSearch("")}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
            >
              <X size={14} />
            </button>
          )}
        </div>
      </div>
    </main>
  );
}

function Brand() {
  return (
    <span className="inline-flex items-center gap-2 text-xl font-bold tracking-tight text-[#242a3b]">
      <span className="grid h-7 w-7 place-items-center rounded-lg bg-[#7657f8] text-base text-white">
        ✓
      </span>
      Taskflow
    </span>
  );
}

function Stat({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <article className="flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-5">
      <div className="grid h-10 w-10 place-items-center rounded-lg bg-slate-50">
        {icon}
      </div>
      <div>
        <p className="text-[10px] font-bold tracking-[.13em] text-slate-400">
          {label}
        </p>
        <p className="mt-1 text-2xl font-bold">{value}</p>
      </div>
    </article>
  );
}

function TaskRow({
  task,
  onToggle,
  onDelete,
}: {
  task: Task;
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
}) {
  const isOverdue =
    task.due_date &&
    !task.completed &&
    new Date(task.due_date) < new Date(new Date().toDateString());

  return (
    <article className="group flex min-h-16 items-center gap-3 border-b border-slate-100 px-4 py-3 last:border-0">
      <button
        onClick={() => onToggle(task.id)}
        className="shrink-0 transition-colors"
      >
        {task.completed ? (
          <CheckCircle2 size={20} className="text-[#7657f8]" />
        ) : (
          <Circle
            size={20}
            className="text-slate-300 transition-colors hover:text-[#7657f8]"
          />
        )}
      </button>

      <div className="min-w-0 flex-1">
        <h3
          className={`text-sm font-semibold ${
            task.completed
              ? "text-slate-400 line-through"
              : "text-slate-700"
          }`}
        >
          {task.title}
        </h3>
        {task.description && (
          <p className="mt-0.5 truncate text-xs text-slate-400">
            {task.description}
          </p>
        )}
      </div>

      {task.due_date && (
        <span
          className={`flex shrink-0 items-center gap-1 text-xs ${
            isOverdue
              ? "font-bold text-red-500"
              : task.completed
                ? "text-slate-300"
                : "text-slate-400"
          }`}
        >
          <CalendarDays size={12} />
          {new Date(task.due_date).toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
          })}
        </span>
      )}

      <button
        onClick={() => onDelete(task.id)}
        className="shrink-0 text-slate-300 opacity-0 transition-all hover:text-red-500 group-hover:opacity-100"
        title="Delete task"
      >
        <Trash2 size={16} />
      </button>
    </article>
  );
}
