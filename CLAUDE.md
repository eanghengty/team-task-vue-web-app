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
├── App.vue                     — auth state, app state, actions, lifecycle; composes all components
└── components/
    ├── LoginView.vue           — full-screen login form; shown when currentUser is null
    ├── AppHeader.vue           — sticky header, clock, New Task / Reminders / Settings / notification bell / user chip / logout
    ├── ToastContainer.vue      — toast notification list
    ├── StatsBar.vue            — total / open / overdue stats cards + members chip
    ├── TabBar.vue              — board / list / reminders / activity log tabs + filters; activity tab admin-only
    ├── BoardView.vue           — kanban columns, drag-and-drop orchestration
    ├── TaskCard.vue            — individual kanban card (draggable); shows PENDING badge for unconfirmed tasks
    ├── ListView.vue            — sortable table view; shows PENDING badge for unconfirmed tasks
    ├── RemindersView.vue       — reminders tab list
    ├── ActivityLogView.vue     — paginated activity log table (admin only); fetches own data from Supabase
    ├── AddTaskModal.vue        — new task form; shows confirmation notice when user assigns to another member
    ├── AddReminderModal.vue    — new reminder form modal
    ├── TaskDetailModal.vue     — task detail with inline edit (restricted), comments section, PENDING badge
    ├── AddMemberModal.vue      — add member form (name, job role, email, password, access, colour); admin only
    ├── NotificationPanel.vue   — dropdown panel showing per-user notifications; accept/decline assignment requests
    └── SettingsSidebar.vue     — right-side settings panel; content is role-gated (see below)

supabase/
├── schema.sql                  — full schema for a fresh DB setup
└── migrations/
    ├── 001_add_member_access.sql                  — adds access column (admin|user) to members
    ├── 002_add_member_credentials.sql             — adds email and password columns to members
    ├── 003_dynamic_task_statuses.sql              — drops status check constraint; creates task_statuses table
    └── 004_activity_comments_notifications.sql    — adds confirmed to tasks; creates task_comments, activity_logs, notifications tables
```

### Auth flow

The app uses a simple custom auth layer — **no Supabase Auth**. Credentials are stored in the `members` table.

1. On load, `currentUser` is `null` → `LoginView` is rendered full-screen.
2. User submits email + password → `login()` queries `members` where `email = X AND password = Y`.
3. On match, `currentUser` is set to the mapped member object, saved to `localStorage`, and `startApp()` is called.
4. On reload, `onMounted` reads `localStorage` and restores the session automatically.
5. Logout clears `currentUser` and `localStorage`, stops intervals, resets all state refs.
6. No registration UI — accounts are pre-created by an admin in the Settings sidebar.

### Role-based access

| Feature | `admin` | `user` |
|---|---|---|
| New Task | ✅ | ✅ (self only without confirmation; others require assignee confirmation) |
| Reminders | ✅ | ✅ |
| Edit / Delete task | ✅ (any task) | ✅ (own assigned tasks only) |
| Activity Log tab | ✅ | ✗ |
| Settings → Members tab | ✅ | ✗ |
| Settings → Task Statuses tab | ✅ | ✗ |
| Settings → Change Password | ✅ (via Members tab) | ✅ (only option shown) |
| Add Member modal | ✅ | ✗ |

### State model (all refs live in `App.vue`)

| Ref | Shape | Purpose |
|-----|-------|---------|
| `currentUser` | `{ id, name, role, color, access, email, password } \| null` | Logged-in member; `null` = unauthenticated |
| `loginError` | `string` | Error message shown on the login form |
| `loginLoading` | `boolean` | Loading state for the login query |
| `tasks` | `{ id, title, desc, assigneeId, priority, due, status, done, confirmed, createdAt }[]` | All tasks; `confirmed: false` = pending assignee acceptance |
| `reminders` | `{ id, title, taskId, datetime, assigneeId, fired }[]` | Standalone + task-linked reminders |
| `members` | `{ id, name, role, color, access, email, password }[]` | Team members |
| `columns` | `{ id, status, label, dot, sortOrder }[]` **ref** | Kanban column definitions loaded from `task_statuses` |
| `notifications` | `{ id, memberId, senderId, type, message, taskId, read, createdAt }[]` **ref** | Per-user notifications fetched on login and polled every 15 s |
| `unreadCount` | computed `number` | Count of `notifications` where `read === false`; drives bell badge |
| `showNotifications` | `boolean` ref | Controls `NotificationPanel` open/close |
| `modals` | reactive object | `add / reminder / detail / member` boolean flags |
| `form / remForm / memberForm` | reactive objects | Controlled inputs for each modal |
| `showSettings` | `boolean` ref | Controls SettingsSidebar open/close |

### Actions in `App.vue`

| Function | Description |
|---|---|
| `login({ email, password })` | Queries `members` by email + password; sets `currentUser`, saves to `localStorage`, calls `startApp()` |
| `logout()` | Clears `currentUser` + `localStorage`, stops intervals, resets all state refs |
| `startApp()` | Starts clock interval, calls `fetchAll()`, then starts reminder + notification poll interval |
| `stopApp()` | Clears clock and reminder/poll intervals |
| `fetchAll()` | Loads members, tasks, reminders, task_statuses, notifications in parallel |
| `fetchNotifications()` | Fetches last 50 notifications for `currentUser`; called in `fetchAll` and every 15 s |
| `logActivity(action, entityType, entityId, message)` | Inserts a row into `activity_logs`; called after every state-changing action |
| `addTask()` | Insert task; if `user` role assigns to another member → `confirmed = false` + sends `task_assignment_request` notification; otherwise sends `task_assigned` notification to assignee |
| `editTask({ id, title, desc, priority, due, status })` | Updates task fields; restricted in UI to assignee or admin |
| `onCommentAdded({ taskId, taskTitle })` | Logs a `task_commented` activity entry (comment itself is saved inside `TaskDetailModal`) |
| `toggleDone(id)` | Flip done; moves to last/first column; logs activity |
| `deleteTask(id)` | Delete task + linked reminders locally and in DB; logs activity |
| `addReminder()` | Insert standalone reminder; logs activity |
| `deleteReminder(id)` | Delete reminder |
| `addMember()` | Insert new member; logs activity |
| `updateMember({ id, … })` | Update member fields; syncs `currentUser` if self-update |
| `deleteMember(id)` | Delete member; logs activity |
| `updateColumn / addStatus / deleteStatus` | Manage `task_statuses` rows |
| `onDrop(status)` | Kanban drag-and-drop; updates status/done; logs activity |
| `markAllNotificationsRead()` | Marks all unread notifications as read in DB and local ref |
| `acceptAssignment(notif)` | Sets `task.confirmed = true`; deletes request notification; sends `task_confirmed` notification to sender |
| `declineAssignment(notif)` | Deletes the task and notification; sends `task_declined` notification to sender |

### Component contract

- **Props down, events up.** `App.vue` passes state as props; components emit named events back.
- `currentUser` is passed as a prop to `AppHeader`, `AddTaskModal`, `TaskDetailModal`, `TabBar`, and `SettingsSidebar` to drive role-gated UI.
- `TaskDetailModal` and `ActivityLogView` call Supabase **directly** for their scoped data (comments, activity logs) — this is intentional to keep App.vue lean. All other DB writes go through App.vue actions.
- `columns` is passed as a prop to `BoardView`, `ListView`, `AddTaskModal`, `TaskDetailModal`, and `SettingsSidebar`.

### `src/utils.js` exports

| Export | Purpose |
|---|---|
| `uid()` | Random string ID — used for toast IDs only |
| `priorityDotColor(p)` | Returns CSS colour for a priority level |
| `isOverdue(task)` | Returns `true` if task has a past due date and is not done |
| `dotToBadgeStyle(dot)` | Returns inline style object `{ background, color, border }` for dynamic status badges |
| `labelToKey(label)` | Slugifies a label to a DB-safe status key: `"In Review"` → `"in_review"` |

### LoginView

- Full-screen centred card shown when `currentUser === null`.
- Accepts `error` (string) and `loading` (boolean) props; emits `login` with `{ email, password }`.
- No registration link — accounts are created by an admin.

### AppHeader

- Accepts `clock`, `currentUser`, `unreadCount` props; emits `open-modal`, `open-settings`, `open-notifications`, `logout`.
- Notification bell shows a red badge when `unreadCount > 0`; clicking emits `open-notifications` which toggles `showNotifications` in App.vue.
- Logout button emits `logout`.

### TaskDetailModal

- Accepts `open`, `task`, `members`, `columns`, `currentUser` props.
- Emits `close`, `toggle-done`, `delete-task`, `edit-task`, `comment-added`.
- **Edit button** shown only when `currentUser.access === 'admin' || task.assigneeId === currentUser.id`. Clicking populates an inline edit form (title, desc, priority, due, status).
- **PENDING badge** shown when `task.confirmed === false`; action buttons are hidden and a warning message is shown instead.
- **Comments section** fetches `task_comments` via Supabase directly when the modal opens or the task changes. All users can add comments via a text input (Enter or Send button). Adding a comment emits `comment-added` so App.vue can log the activity.

### NotificationPanel

- Fixed dropdown below the bell button (`top: 56px, right: 16px`), `z-[260]`.
- Accepts `open` and `notifications` (camelCase mapped from DB) props.
- Emits `close`, `mark-all-read`, `accept`, `decline`.
- Notification types and their icons/colours:
  - `task_assigned` — blue, `assignment_ind`
  - `task_assignment_request` — accent yellow, `assignment_late`; shows Accept / Decline buttons
  - `task_confirmed` — teal, `check_circle`
  - `task_declined` — red, `cancel`
- Unread notifications have an accent dot and a highlighted background.

### ActivityLogView

- Admin-only tab rendered when `currentTab === 'activity'`.
- Fetches its own data directly from Supabase using a join on `actor_id → members`.
- Paginated: 20 entries per page, oldest-first within page, newest pages first overall.
- Has a Refresh button and Prev/Next pagination controls.

### AddTaskModal

- Accepts `currentUser` prop.
- When `currentUser.access === 'user'` and `form.assigneeId !== currentUser.id`, shows an inline notice: "The assignee will receive a notification to confirm this task."

### TabBar

- Accepts `currentUser` prop.
- **Activity Log tab** rendered only when `currentUser.access === 'admin'`.

### SettingsSidebar

- **Admin view:** Members tab + Task Statuses tab.
- **User view:** Change Password form only (no tabs).
- Emits: `close`, `open-add-member`, `update-member`, `delete-member`, `update-status`, `add-status`, `delete-status`.

### TaskCard / ListView

- Both show an orange **PENDING** badge when `task.confirmed === false`.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root`.
- Status badge colours derived at runtime via `dotToBadgeStyle(dot)`.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).
- Icons: **Google Material Icons** via CDN. Use `<span class="material-icons">icon_name</span>` — no emoji.

### Key behaviours

- **Auth gate** — `LoginView` shown via `v-if="!currentUser"`. Full app in `<template v-else>`. No data fetched until login succeeds.
- **Session persistence** — `currentUser` saved to `localStorage` on login; restored in `onMounted` to survive page reloads.
- **Task confirmation** — tasks with `confirmed = false` are created by non-admin users assigning to others. They show a PENDING badge everywhere and block action buttons in the detail modal. Assignee accepts/declines via `NotificationPanel`.
- **Edit restriction** — Edit and Delete buttons in `TaskDetailModal` only render when `currentUser.access === 'admin' || task.assigneeId === currentUser.id`.
- **Activity logging** — `logActivity()` is called after every significant action. Logs are never deleted (no cap). The Activity Log view paginates them.
- **Notification polling** — notifications are re-fetched inside the same 15 s interval as the reminder checker. `unreadCount` drives the bell badge reactively.
- **Tab views** use `v-if` — no entry animations on per-item elements (causes flicker on tab switch).
- **Drag-and-drop** — native HTML5 events. `dragTaskId` tracks in-flight card; `dragOver` drives highlight. Status change logged after drop.
- **Optimistic updates** — all actions mutate local refs immediately, then write to Supabase. Errors surface as red toasts.
- **Dynamic statuses** — no DB check constraint on `tasks.status`. Valid keys are whatever rows exist in `task_statuses`.
- **Self-update sync** — `updateMember` patches `currentUser` when the updated member is the logged-in user.

### Data flow

```
user action (component event)
  → App.vue handler mutates tasks / reminders / members / columns / notifications refs
  → computed filteredTasks / unreadCount update automatically
  → props re-render BoardView / ListView / StatsBar / SettingsSidebar / AppHeader
```

State is persisted in **Supabase Postgres**. See [SUPABASE.md](./SUPABASE.md) for full database documentation.
