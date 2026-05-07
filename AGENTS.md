# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

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
    ├── TabBar.vue              — board / list / chat / reminders / activity log tabs + filters; activity tab admin-only
    ├── BoardView.vue           — kanban columns, drag-and-drop orchestration
    ├── TaskCard.vue            — individual kanban card (draggable); shows PENDING badge for unconfirmed tasks
    ├── ListView.vue            — sortable table view; shows PENDING badge for unconfirmed tasks
    ├── RemindersView.vue       — reminders tab list
    ├── ChatView.vue            — workspace group chat view (message list + composer)
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
    ├── 004_activity_comments_notifications.sql    — adds confirmed to tasks; creates task_comments, activity_logs, notifications tables
    ├── 005_workspace_ownership.sql                — adds workspaces + workspace_members and scopes core tables
    ├── 006_done_status_config.sql                 — adds task_statuses.is_done for configurable done state
    ├── 007_workspace_chat.sql                     — adds workspace_messages + workspace_chat_reads and chat realtime publication
    ├── 008_workspace_chat_replies.sql             — adds `workspace_messages.reply_to_message_id` for chat reply threading
    └── 009_motivational_quotes.sql                — adds `motivational_quotes` table and seeds 10 fixed quotes
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
| Drag task to new column | ✅ (any task) | ✅ (own assigned tasks only) |
| Mark task as done | ✅ (any task) + notifies assignee | ✅ (own tasks only) |
| Reopen task (mark undone) | ✅ (any task) + notifies assignee | ✅ own task; sends `task_reopen_request` for others |
| Activity Log tab | ✅ | ✗ |
| Settings → Members tab | ✅ | ✗ |
| Settings → Task Statuses tab | ✅ | ✗ |
| Settings → Appearance (theme) | ✅ | ✅ |
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
| `notifications` | `{ id, memberId, senderId, type, message, taskId, read, createdAt }[]` **ref** | Per-user notifications; populated on login then kept live via Supabase Realtime |
| `chatMessages` | `{ id, workspaceId, senderId, content, createdAt }[]` **ref** | Workspace chat timeline (latest 100 messages) |
| `chatLastReadAt` | `string \| null` **ref** | Last read timestamp for current user in current workspace |
| `unreadCount` | computed `number` | Count of `notifications` where `read === false`; drives bell badge |
| `chatUnreadCount` | computed `number` | Count of unseen chat messages in current workspace excluding own messages |
| `showNotifications` | `boolean` ref | Controls `NotificationPanel` open/close |
| `taskSubmitting` | `boolean` ref | Controls AddTaskModal loading/disabled state during task assignment |
| `taskLoadingQuote` | `string` ref | Current motivational quote shown under assignment Lottie |
| `isDark` | `boolean` ref | `true` = dark mode (default); persisted in `localStorage` as `squad_theme` |
| `modals` | reactive object | `add / reminder / detail / member` boolean flags |
| `form / remForm / memberForm` | reactive objects | Controlled inputs for each modal |
| `showSettings` | `boolean` ref | Controls SettingsSidebar open/close |

### Actions in `App.vue`

| Function | Description |
|---|---|
| `login({ email, password })` | Queries `members` by email + password; sets `currentUser`, saves to `localStorage`, calls `startApp()` |
| `logout()` | Clears `currentUser` + `localStorage`, stops intervals + realtime channels, resets all state refs |
| `startApp()` | Starts clock interval, calls `fetchAll()`, then calls `startRealtimeSync()` and starts reminder interval |
| `stopApp()` | Clears clock and reminder intervals; calls `stopRealtimeSync()` |
| `fetchAll()` | Loads members, tasks, reminders, task_statuses, notifications in parallel (one-time snapshot on login) |
| `fetchNotifications()` | Fetches last 50 notifications for `currentUser`; called once in `fetchAll` only |
| `fetchWorkspaceMessages(workspaceId)` | Fetches latest 100 workspace chat messages (DESC in DB), then reverses client-side for oldest ? newest rendering |
| `fetchChatReadState(workspaceId, memberId)` | Fetches chat read cursor (`last_read_at`) for unread count calculation |
| `fetchMotivationQuotes()` | Fetches motivational quotes from `motivational_quotes` table |
| `setRandomTaskLoadingQuote()` | Picks a random quote (Supabase first, fallback pool if unavailable) |
| `fetchTasks()` | Fetches all tasks; available for manual refresh if needed |
| `startRealtimeSync()` | Opens three Supabase Realtime WebSocket channels: `db-tasks`, `db-notifications`, and `db-workspace-messages` (workspace-scoped). Patches local arrays in-place |
| `stopRealtimeSync()` | Removes all active Realtime channels |
| `notifyAdmins(type, message, taskId)` | Bulk-inserts a notification row for every admin except the current user |
| `applyTheme(dark)` | Sets `data-theme` attribute on `<html>` to `'dark'` or `'light'` |
| `toggleTheme()` | Flips `isDark`, calls `applyTheme`, persists to `localStorage` as `squad_theme` |
| `logActivity(action, entityType, entityId, message)` | Inserts a row into `activity_logs`; called after every state-changing action |
| `addTask()` | Insert task; if `user` role assigns to another member → `confirmed = false` + sends `task_assignment_request` to assignee + notifies admins; otherwise sends `task_assigned` to assignee + notifies admins |
| `editTask({ id, title, desc, priority, due, status })` | Updates task fields; guarded — non-admin non-assignee gets error toast and early return |
| `onCommentAdded({ taskId, taskTitle })` | Logs `task_commented` activity; if actor is a user role, notifies all admins via `notifyAdmins` |
| `toggleDone(id)` | Permission-gated: admin → immediate + notifies assignee; own task → immediate; user marking other's done → blocked; user reopening other's task → sends `task_reopen_request` to assignee |
| `deleteTask(id)` | Delete task + linked reminders locally and in DB; logs activity |
| `addReminder()` | Insert standalone reminder; logs activity |
| `deleteReminder(id)` | Delete reminder |
| `addMember()` | Insert new member; logs activity |
| `updateMember({ id, … })` | Update member fields; syncs `currentUser` if self-update |
| `deleteMember(id)` | Delete member; logs activity |
| `updateColumn / addStatus / deleteStatus` | Manage `task_statuses` rows |
| `reorderColumn(status, direction)` | Reorder kanban columns: swaps positions and renumbers all `sort_order` values sequentially (0, 1, 2...); direction is 'up' or 'down'; shows success toast on completion |
| `onDrop(status)` | Kanban drag-and-drop; guarded — non-admin non-assignee blocked; logs activity; notifies admins if actor is user role |
| `sendWorkspaceMessage(payload)` | Sends a workspace chat/reply message with validation (`trim`, max 2000 chars), appends locally, fans out workspace notifications, logs activity |
| `notifyWorkspaceMembers(type, message, workspaceId, senderId)` | Sends notifications to all members in the workspace except the sender |
| `deleteWorkspaceMessage(messageId)` | Admin-only chat moderation: delete one message with rollback on failure |
| `deleteAllWorkspaceMessages()` | Admin-only chat moderation: delete all workspace messages for current workspace with rollback on failure |
| `markChatRead()` | Updates `workspace_chat_reads.last_read_at` when user is on Chat tab |
| `markAllNotificationsRead()` | Marks all unread notifications as read in DB and local ref |
| `acceptAssignment(notif)` | Sets `task.confirmed = true`; deletes request notification; sends `task_confirmed` to sender |
| `declineAssignment(notif)` | Deletes the task and notification; sends `task_declined` to sender |
| `acceptReopenRequest(notif)` | Reopens the task (done=false, moves to first column); deletes request notification; sends `task_reopen_accepted` to sender |
| `declineReopenRequest(notif)` | Deletes the request notification; sends `task_reopen_declined` to sender |

### Component contract

- **Props down, events up.** `App.vue` passes state as props; components emit named events back.
- `currentUser` is passed as a prop to `AppHeader`, `AddTaskModal`, `TaskDetailModal`, `TabBar`, `BoardView`, `ListView`, and `SettingsSidebar` to drive role-gated UI and permission checks.
- `TaskDetailModal` and `ActivityLogView` call Supabase **directly** for their scoped data (comments, activity logs) — this is intentional to keep App.vue lean. All other DB writes go through App.vue actions.
- `columns` is passed as a prop to `BoardView`, `ListView`, `AddTaskModal`, `TaskDetailModal`, and `SettingsSidebar`.
- `isDark` is passed to `SettingsSidebar`; theme is toggled via `toggle-theme` emit back to `App.vue`.

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
- **Mark Done / Reopen button** gated by the same `canEdit` computed — hidden for non-owners.
- **PENDING badge** shown when `task.confirmed === false`; action buttons are hidden and a warning message is shown instead.
- **Comments section** fetches `task_comments` via Supabase directly when the modal opens or the task changes. All users can add comments via a text input (Enter or Send button). Adding a comment emits `comment-added` so App.vue can log the activity.

### NotificationPanel

- Fixed dropdown below the bell button (`top: 56px, right: 16px`), `z-[260]`.
- Accepts `open` and `notifications` (camelCase mapped from DB) props.
- Emits `close`, `mark-all-read`, `accept`, `decline`.
- `App.vue` routes `accept`/`decline` events by `notif.type` to the correct handler.
- Notification types and their icons/colours:

| Type | Icon | Colour | Accept/Decline |
|---|---|---|---|
| `task_assigned` | `assignment_ind` | blue | — |
| `task_assignment_request` | `assignment_late` | accent yellow | ✅ |
| `task_confirmed` | `check_circle` | teal | — |
| `task_declined` | `cancel` | red | — |
| `task_commented` | `chat_bubble` | gray | — |
| `task_status_changed` | `swap_horiz` | blue | — |
| `task_reopen_request` | `refresh` | accent yellow | ✅ |
| `task_reopen_accepted` | `check_circle` | teal | — |
| `task_reopen_declined` | `cancel` | red | — |
| `task_marked_done` | `task_alt` | blue | — |
| `task_reopened` | `replay` | blue | — |

- Unread notifications have an accent dot and a highlighted background.

### ActivityLogView

- Admin-only tab rendered when `currentTab === 'activity'`.
- Fetches its own data directly from Supabase using a join on `actor_id → members`.
- Paginated: 20 entries per page, oldest-first within page, newest pages first overall.
- Has a Refresh button and Prev/Next pagination controls.

### AddTaskModal

- Accepts `currentUser`, `submitting`, and `loadingQuote` props.
- When `currentUser.access === 'user'` and `form.assigneeId !== currentUser.id`, shows an inline notice: "The assignee will receive a notification to confirm this task."
- During submit, shows a full modal loading overlay with Lottie animation and a motivational quote, and disables close/inputs/buttons.

### TabBar

- Accepts `currentUser` prop.
- Includes a **Chat tab** with unread badge from `chatUnreadCount`.
- **Activity Log tab** rendered only when `currentUser.access === 'admin'`.
- Member/priority filters are hidden when `currentTab === 'chat'`.

### ChatView

- Workspace-scoped group chat view rendered when `currentTab === 'chat'`.
- Accepts `messages`, `members`, and `currentUser` props.
- Emits `send-message`, `mark-read`, `delete-message`, and `delete-all-messages`.
- Composer trims input, supports Enter-to-send, and enforces max length 2000 characters.
- Includes compact message replies:
  - each message has a `Reply` action
  - composer shows a compact "Replying to …" bar with cancel
  - replied messages render compact parent-message preview in the timeline
- Admin moderation:
  - admins can delete individual messages
  - admins can delete all chat messages in the current workspace
  - destructive actions require confirmation prompts

### SettingsSidebar

- Accepts `isDark` (Boolean) prop in addition to existing props.
- **Appearance section** — shown to all users at the top of the scrollable body. Displays current theme name and a toggle button (`light_mode` / `dark_mode` icon). Emits `toggle-theme`.
- **Admin view:** Members tab + Task Statuses tab (below Appearance section).
- **User view:** Change Password form (below Appearance section).
- **Task Statuses tab:** Each status row has up/down arrow buttons for reordering. Buttons are disabled (dimmed) for the first and last columns. Emits `reorder-status` with the status key and direction ('up' or 'down').
- Emits: `close`, `open-add-member`, `update-member`, `delete-member`, `update-status`, `add-status`, `delete-status`, `reorder-status`, `toggle-theme`.

### BoardView

- Accepts `currentUser` prop (in addition to existing props).
- `canDrag(task)` helper — returns `true` when `currentUser.access === 'admin'` or `task.assigneeId === currentUser.id`.
- Passes `:can-drag="canDrag(task)"` to each `TaskCard`.
- Includes a fixed **Back to Top** button that appears after vertical scrolling and smoothly scrolls `window` to top.

### TaskCard / ListView

- Both show an orange **PENDING** badge when `task.confirmed === false`.
- **`TaskCard`** — accepts `canDrag` (Boolean, default `true`) prop. `:draggable="canDrag"`. Checkbox click blocked (dimmed, `cursor: not-allowed`) when `canDrag` is false.
- **`ListView`** — accepts `currentUser` prop. `canAct(task)` helper gates the checkbox the same way.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root` (dark defaults).
- **Light mode** — `[data-theme="light"]` block in `style.css` overrides all 9 CSS variables. `applyTheme(dark)` sets `data-theme` on `<html>`. Targeted overrides for noise opacity, select option background, modal backdrop, card/toast shadows, drag-over tint, and ghost button hover.
- Status badge colours derived at runtime via `dotToBadgeStyle(dot)`.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).
- Icons: **Google Material Icons** via CDN. Use `<span class="material-icons">icon_name</span>` — no emoji.

### Key behaviours

- **Auth gate** — `LoginView` shown via `v-if="!currentUser"`. Full app in `<template v-else>`. No data fetched until login succeeds.
- **Session persistence** — `currentUser` saved to `localStorage` on login; restored in `onMounted` to survive page reloads.
- **Workspace persistence** — `currentWorkspaceId` is restored from `localStorage` (`squad_workspace`) on reload, and `sessionWorkspaceChosen` is restored to avoid re-opening `WorkspaceGateView` after refresh.
- **Theme persistence** — `isDark` initialised from `localStorage` key `squad_theme`. Applied to `<html data-theme>` immediately in `onMounted` before first render.
- **Task confirmation** — tasks with `confirmed = false` are created by non-admin users assigning to others. They show a PENDING badge everywhere and block action buttons in the detail modal. Assignee accepts/declines via `NotificationPanel`.
- **Permission enforcement** — all mutating actions (`editTask`, `onDrop`, `toggleDone`) guard at the action level in `App.vue` in addition to UI-level gating. Non-owner non-admin calls return early with an error toast.
- **Reopen approval flow** — when a `user` tries to reopen a task assigned to someone else, a `task_reopen_request` notification is sent to the assignee with Accept/Decline buttons. Admin reopens bypass the flow and notify the assignee directly.
- **Admin activity notifications** — `notifyAdmins()` sends notifications to all admins when a user role: comments on a task (`task_commented`), assigns a task to someone (`task_assigned`), or moves a task to a new status (`task_status_changed`).
- **Edit restriction** — Edit, Delete, and Mark Done buttons in `TaskDetailModal` only render when `currentUser.access === 'admin' || task.assigneeId === currentUser.id`.
- **Activity logging** — `logActivity()` is called after every significant action. Logs are never deleted (no cap). The Activity Log view paginates them.
- **Chat** — workspace group chat is realtime via `workspace_messages`; unread count is computed from `workspace_chat_reads.last_read_at` and excludes self-sent messages.
- **Chat hydration fallback** — entering Chat tab triggers a fresh message + read-state fetch so members can always see history even if realtime misses prior inserts.
- **Chat notifications** — each new chat/reply sends a `chat_message` notification to all other workspace members; recipients see a top-right popup for 5s with `<username> - New message` (no message content).
- **Realtime sync** — after workspace selection, `startRealtimeSync()` opens three Realtime channels: tasks, notifications, and workspace chat messages. Requires `tasks`, `notifications`, and `workspace_messages` to be in `supabase_realtime`.
- **Reload hydration** — when a saved workspace exists, startup now fetches full workspace data and starts realtime immediately (without requiring a manual workspace switch).
- **Task assignment loading** — task creation now enforces a minimum 7-second loading state with Lottie animation before modal closes.
- **Motivational quote loading text** — assignment loading overlay shows only a motivational quote (no "Assigning task..." text), randomized from Supabase quotes when available.
- **Reminder interval** — still runs every 15 s but now only checks for due reminders; no longer fetches tasks or notifications.
- **Tab views** use `v-if` — no entry animations on per-item elements (causes flicker on tab switch).
- **Drag-and-drop** — native HTML5 events. `dragTaskId` tracks in-flight card; `dragOver` drives highlight. Cards are non-draggable (`:draggable="false"`) for tasks the current user does not own. Status change logged after drop.
- **Optimistic updates** — all actions mutate local refs immediately, then write to Supabase. Errors surface as red toasts.
- **Dynamic statuses** — no DB check constraint on `tasks.status`. Valid keys are whatever rows exist in `task_statuses`.
- **Self-update sync** — `updateMember` patches `currentUser` when the updated member is the logged-in user.

### Data flow

```
user action (component event)
  → App.vue handler mutates tasks / reminders / members / columns / notifications / chatMessages refs
  → computed filteredTasks / unreadCount / chatUnreadCount update automatically
  → props re-render BoardView / ListView / ChatView / StatsBar / SettingsSidebar / AppHeader
```

State is persisted in **Supabase Postgres**. See [SUPABASE.md](./SUPABASE.md) for full database documentation.


### Latest updates (v3.12.6)

- Added `motivational_quotes` support with migration `009_motivational_quotes.sql` (10 fixed seeded quotes).
- AddTaskModal loading overlay now displays a random motivational quote under Lottie during task assignment.
- Assignment overlay text was simplified to quote-only (removed static "Assigning task..." line).

### Previous updates (v3.12.5)

- Added workspace-wide chat/reply notifications (`chat_message`) with sender excluded.
- Added top-right 5-second popup for incoming chat/reply events showing `<username> - New message`.
- Removed duplicate header chat icon entry point; chat now uses tab-only navigation/badge.
- Added AddTaskModal submit loading overlay with Lottie embed and minimum 7-second assignment loading state.

### Previous updates (v3.12.4)

- Added admin-only chat moderation actions in `ChatView`: delete one message and delete all workspace messages.
- Added `App.vue` handlers `deleteWorkspaceMessage` and `deleteAllWorkspaceMessages` with admin permission guards, optimistic rollback, and activity logs.
- Added realtime `DELETE` sync for `workspace_messages` so all connected members see chat deletions immediately.

### Previous updates (v3.12.3)

- Added compact chat reply UI and reply threading support in `ChatView`.
- Added DB migration `008_workspace_chat_replies.sql` and schema support for `workspace_messages.reply_to_message_id`.
- Reply messages now persist parent links so reply context survives reload and is visible to all workspace members.

### Previous updates (v3.12.2)

- Added BoardView fixed **Back to Top** button for long board pages.
- Button appears after scroll threshold and uses smooth scroll-to-top behavior.

### Previous updates (v3.12.1)

- Fixed startup hydration issue where reload could show empty data until manually switching workspace.
- Fixed chat visibility for workspace members by refreshing chat data on Chat tab entry.
- Adjusted chat history fetch to guarantee latest 100 messages are loaded and rendered in chronological order.

### Previous updates (v3.12.0)

- Added workspace member group chat with a new Chat tab (`ChatView.vue`).
- Added `workspace_messages` and `workspace_chat_reads` tables with migration `007_workspace_chat.sql`.
- Added realtime channel `db-workspace-messages` filtered by active workspace.
- Added chat unread badges in `AppHeader` and `TabBar`.
- Added workspace restore on reload so workspace gate is login-first, not refresh-first.


