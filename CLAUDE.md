# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev       # start dev server at http://localhost:6005
npm run build     # production build → dist/
npm run preview   # preview production build locally
```

There are no tests or lint scripts configured.

## Architecture

Single-page Vue 3 app (Composition API + `<script setup>`). State and business logic live in **`src/App.vue`**; the UI is split across focused components in **`src/components/`**.

### File structure

```
src/
├── utils.js                    — pure helpers: uid, statusLabel, statusBadgeClass, priorityDotColor, isOverdue
├── App.vue                     — state, actions, lifecycle; composes all components
└── components/
    ├── AppHeader.vue           — sticky header, clock, New Task / Reminders buttons
    ├── ToastContainer.vue      — toast notification list
    ├── StatsBar.vue            — total / open / overdue stats cards + members chip
    ├── TabBar.vue              — board / list / reminders tabs + member & priority filters
    ├── BoardView.vue           — kanban columns, drag-and-drop orchestration
    ├── TaskCard.vue            — individual kanban card (draggable)
    ├── ListView.vue            — sortable table view of tasks
    ├── RemindersView.vue       — reminders tab list
    ├── AddTaskModal.vue        — new task form modal
    ├── AddReminderModal.vue    — new reminder form modal
    ├── TaskDetailModal.vue     — task detail / mark done / delete modal
    └── AddMemberModal.vue      — add member form modal
```

### State model (all refs live in `App.vue`)

| Ref | Shape | Purpose |
|-----|-------|---------|
| `tasks` | `{ id, title, desc, assigneeId, priority, due, status, done, createdAt }[]` | All tasks |
| `reminders` | `{ id, title, taskId, datetime, assigneeId, fired }[]` | Standalone + task-linked reminders |
| `members` | `{ id, name, role, color }[]` | Team members; seeded with 3 defaults |
| `modals` | reactive object | `add / reminder / detail / member` boolean flags |
| `form / remForm / memberForm` | reactive objects | Controlled inputs for each modal |

`status` is the source of truth for which Kanban column a task belongs to (`todo | progress | review | done`). `done` is a boolean mirror that is set `true` when status becomes `'done'` and cleared otherwise.

### Component contract

- **Props down, events up.** `App.vue` passes state as props; components emit named events (`open-modal`, `toggle-done`, `delete-task`, etc.) back to `App.vue`.
- Modal form objects (`form`, `remForm`, `memberForm`) are reactive objects passed by reference — child components bind `v-model` directly against them.
- Pure helper functions (`isOverdue`, `priorityDotColor`, etc.) are imported from `src/utils.js` in any component that needs them — never duplicated.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root` are used throughout both the stylesheet and inline `:style` bindings in the template. Prefer inline style for one-off color references, `@layer components` for reusable patterns.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).
- Icons: **Google Material Icons** loaded via CDN in `index.html`. Use `<span class="material-icons">icon_name</span>` — no emoji in the UI.

### Key behaviours

- **Tab views** use `v-if` — each view is fully destroyed and remounted on tab switch. Do **not** add entry animations (e.g. `fade-up`) to per-item elements inside these views; they will re-fire on every tab switch and cause a flicker. Reserve `fade-up` for genuinely new items added at runtime.
- **Drag-and-drop** — native HTML5 drag events on `.task-card` / `.column`. `dragTaskId` ref tracks the in-flight card; `dragOver` ref drives the `.drag-over` highlight class. Events bubble up from `TaskCard` → `BoardView` → `App.vue`.
- **Reminder checker** — `setInterval` every 15 s fires toasts for any reminder whose `datetime ≤ now` and `fired === false`, then marks `fired = true`.
- **Toasts** — managed as a `toasts` ref array. Each toast auto-removes after a configurable duration via `fading` flag + CSS `slideOut` animation.
- **Filters** (`filterMember`, `filterPriority`) are top-level refs in `App.vue`; `filteredTasks` is a computed that `BoardView` and `ListView` both receive as a prop.

### Data flow

```
user action (component event)
  → App.vue handler mutates tasks / reminders / members refs
  → computed filteredTasks updates automatically
  → props re-render BoardView / ListView / StatsBar
```

State is persisted in **Supabase Postgres**. On mount, `fetchAll()` loads all three tables in parallel. Every action (add/update/delete) writes to Supabase; local refs are updated optimistically for instant UI feedback.

### Supabase setup

1. Run `supabase/schema.sql` in your Supabase SQL editor to create the three tables.
2. Copy `.env.example` → `.env` and fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from your Supabase project settings. The anon key must be the **`anon public`** JWT (starts with `eyJ`, ~200 chars) — not the `sb_secret_...` format which causes 401 errors.
3. `.env` is git-ignored — never commit it.

### DB ↔ JS column mapping

Postgres uses snake_case; JS uses camelCase. Three mapper functions in `App.vue` handle the translation:

| Table column | JS field |
|---|---|
| `description` | `desc` |
| `assignee_id` | `assigneeId` |
| `task_id` | `taskId` |
| `created_at` | `createdAt` |

### Tables

| Table | Key columns |
|---|---|
| `members` | `id uuid`, `name`, `role`, `color` |
| `tasks` | `id uuid`, `title`, `description`, `assignee_id`, `priority`, `due`, `status`, `done` |
| `reminders` | `id uuid`, `title`, `task_id`, `datetime`, `assignee_id`, `fired` |
