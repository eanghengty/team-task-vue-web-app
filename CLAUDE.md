# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev       # start dev server at http://localhost:6005
npm run build     # production build → dist/
npm run preview   # preview production build locally
```

### Supabase CLI scripts

```bash
npm run db:login  # authenticate with Supabase account
npm run db:link   # link to a Supabase project
npm run db:push   # apply local migrations to the remote DB
npm run db:pull   # pull remote schema as a new migration
npm run db:diff   # diff local vs remote schema
npm run db:reset  # reset and re-run all migrations
npm run db:types  # generate TypeScript types → src/types/supabase.ts
```

There are no tests or lint scripts configured.

## Architecture

Single-page Vue 3 app (Composition API + `<script setup>`). State and business logic live in **`src/App.vue`**; the UI is split across focused components in **`src/components/`**.

### File structure

```
src/
├── utils.js                    — pure helpers: uid, priorityDotColor, isOverdue, dotToBadgeStyle, labelToKey
├── lib/
│   └── supabase.js             — Supabase client (reads VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY)
├── App.vue                     — state, actions, lifecycle; composes all components
└── components/
    ├── AppHeader.vue           — sticky header, clock, New Task / Reminders / Settings buttons
    ├── ToastContainer.vue      — toast notification list
    ├── StatsBar.vue            — total / open / overdue stats cards + members chip
    ├── TabBar.vue              — board / list / reminders tabs + member & priority filters
    ├── BoardView.vue           — kanban columns, drag-and-drop orchestration
    ├── TaskCard.vue            — individual kanban card (draggable)
    ├── ListView.vue            — sortable table view of tasks
    ├── RemindersView.vue       — reminders tab list
    ├── AddTaskModal.vue        — new task form modal; status options driven by columns prop
    ├── AddReminderModal.vue    — new reminder form modal
    ├── TaskDetailModal.vue     — task detail / mark done / delete modal; status label from columns prop
    ├── AddMemberModal.vue      — add member form (name, job role, email, password, access, colour)
    └── SettingsSidebar.vue     — right-side settings panel (members + task statuses)

supabase/
├── schema.sql                  — full schema for a fresh DB setup
└── migrations/
    ├── 001_add_member_access.sql       — adds access column (admin|user) to members
    ├── 002_add_member_credentials.sql  — adds email and password columns to members
    └── 003_dynamic_task_statuses.sql   — drops status check constraint; creates task_statuses table
```

### State model (all refs live in `App.vue`)

| Ref | Shape | Purpose |
|-----|-------|---------|
| `tasks` | `{ id, title, desc, assigneeId, priority, due, status, done, createdAt }[]` | All tasks |
| `reminders` | `{ id, title, taskId, datetime, assigneeId, fired }[]` | Standalone + task-linked reminders |
| `members` | `{ id, name, role, color, access, email, password }[]` | Team members — `access` is `'admin' \| 'user'`; `email`/`password` are login credentials |
| `columns` | `{ id, status, label, dot, sortOrder }[]` **ref** | Kanban column definitions loaded from `task_statuses` table; fully dynamic |
| `modals` | reactive object | `add / reminder / detail / member` boolean flags |
| `form / remForm / memberForm` | reactive objects | Controlled inputs for each modal |
| `showSettings` | `boolean` ref | Controls SettingsSidebar open/close |

`status` on a task stores the `key` value of its `task_statuses` row — this is what determines which kanban column the task belongs to. `done` is a boolean mirror set `true` when the task is moved to the **last** column, cleared otherwise.

### Actions in `App.vue`

| Function | Description |
|---|---|
| `fetchAll()` | Loads members, tasks, reminders, task_statuses in parallel on mount |
| `addTask()` | Insert task (+ optional linked reminder); resets `form.status` to first column key |
| `toggleDone(id)` | Flip done; moves to last column when marking done, first column when reopening |
| `deleteTask(id)` | Delete task + cascade-remove linked reminders locally |
| `addReminder()` | Insert standalone reminder |
| `deleteReminder(id)` | Delete reminder |
| `addMember()` | Insert new member with name, role, email, password, access, colour |
| `updateMember({ id, name, role, email, password, color, access })` | Update member fields; password only patched if non-empty |
| `deleteMember(id)` | Delete member from DB and local ref |
| `updateColumn({ status, label, dot })` | Persist label/dot change to `task_statuses` row in DB |
| `addStatus({ label, dot })` | Insert new `task_statuses` row; key auto-generated via `labelToKey()` |
| `deleteStatus(status)` | Delete status from DB and `columns` ref; blocked if tasks still use it |
| `onDrop(status)` | Handle kanban drag-and-drop; updates task status in DB |

### Component contract

- **Props down, events up.** `App.vue` passes state as props; components emit named events (`open-modal`, `toggle-done`, `delete-task`, etc.) back to `App.vue`.
- Modal form objects (`form`, `remForm`, `memberForm`) are reactive objects passed by reference — child components bind `v-model` directly against them.
- Pure helper functions (`isOverdue`, `priorityDotColor`, `dotToBadgeStyle`, `labelToKey`) are imported from `src/utils.js` in any component that needs them — never duplicated.
- `columns` is passed as a prop to `BoardView`, `ListView`, `AddTaskModal`, `TaskDetailModal`, and `SettingsSidebar` so all status labels and colours are resolved from live DB data — no hardcoded status strings in components.

### `src/utils.js` exports

| Export | Purpose |
|---|---|
| `uid()` | Random string ID — used for toast IDs only |
| `priorityDotColor(p)` | Returns CSS colour for a priority level |
| `isOverdue(task)` | Returns `true` if task has a past due date and is not done |
| `dotToBadgeStyle(dot)` | Returns inline style object `{ background, color, border }` derived from a hex dot colour — used for dynamic status badges |
| `labelToKey(label)` | Slugifies a label to a DB-safe status key: `"In Review"` → `"in_review"` |

### SettingsSidebar

- Right-side sliding panel, fixed position, `z-[260]`, `width: 440px`.
- Two internal tabs: **Members** and **Task Statuses** (controlled by local `activeTab` ref inside the component).
- **Members tab:** inline-edit name / role / email / password (show/hide toggle, blank = keep current) / colour / access; delete member; reveal/hide password toggle in view state; "+ Add Member" emits `open-add-member` → `App.vue` opens `modals.member`.
- **Task Statuses tab:** add new status (label + colour picker → key auto-previewed); inline-edit label/dot for existing rows; delete status (blocked with a toast if tasks are using it).
- Emits: `close`, `open-add-member`, `update-member`, `delete-member`, `update-status`, `add-status`, `delete-status`.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root` are used throughout both the stylesheet and inline `:style` bindings in the template. Prefer inline style for one-off color references, `@layer components` for reusable patterns.
- Status badge colours are derived at runtime via `dotToBadgeStyle(dot)` — do **not** use the old `badge-yellow` / `badge-blue` CSS classes for status badges; those remain only for non-status uses.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).
- Icons: **Google Material Icons** loaded via CDN in `index.html`. Use `<span class="material-icons">icon_name</span>` — no emoji in the UI.

### Key behaviours

- **Tab views** use `v-if` — each view is fully destroyed and remounted on tab switch. Do **not** add entry animations (e.g. `fade-up`) to per-item elements inside these views; they will re-fire on every tab switch and cause a flicker. Reserve `fade-up` for genuinely new items added at runtime.
- **Drag-and-drop** — native HTML5 drag events on `.task-card` / `.column`. `dragTaskId` ref tracks the in-flight card; `dragOver` ref drives the `.drag-over` highlight class. Events bubble up from `TaskCard` → `BoardView` → `App.vue`.
- **Reminder checker** — `setInterval` every 15 s fires toasts for any reminder whose `datetime ≤ now` and `fired === false`, then marks `fired = true` in Supabase.
- **Toasts** — managed as a `toasts` ref array. Each toast auto-removes after a configurable duration via `fading` flag + CSS `slideOut` animation.
- **Filters** (`filterMember`, `filterPriority`) are top-level refs in `App.vue`; `filteredTasks` is a computed that `BoardView` and `ListView` both receive as a prop.
- **Optimistic updates** — all actions mutate local refs immediately, then write to Supabase. Errors surface as red toasts; local state is not rolled back (page refresh restores DB truth).
- **Dynamic statuses** — `tasks.status` is a free-text field with no DB check constraint. Valid keys are whatever rows exist in `task_statuses`. Adding/deleting statuses in Settings is reflected immediately across all views.

### Data flow

```
user action (component event)
  → App.vue handler mutates tasks / reminders / members / columns refs
  → computed filteredTasks updates automatically
  → props re-render BoardView / ListView / StatsBar / SettingsSidebar
```

State is persisted in **Supabase Postgres**. See [SUPABASE.md](./SUPABASE.md) for full database documentation.
