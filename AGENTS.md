# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev       # start dev server at http://localhost:6005
npm run build     # production build â†’ dist/
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
npm run db:types  # generate TypeScript types â†’ src/types/supabase.ts
```

There are no tests or lint scripts configured.

## Architecture

Single-page Vue 3 app (Composition API + `<script setup>`). State and business logic live in **`src/App.vue`**; the UI is split across focused components in **`src/components/`**.

### File structure

```
src/
â”œâ”€â”€ utils.js                    â€” pure helpers: uid, priorityDotColor, isOverdue, dotToBadgeStyle, labelToKey
â”œâ”€â”€ lib/
â”‚   â””â”€â”€ supabase.js             â€” Supabase client (reads VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY)
â”œâ”€â”€ App.vue                     â€” auth state, app state, actions, lifecycle; composes all components
â””â”€â”€ components/
    â”œâ”€â”€ LoginView.vue           â€” full-screen login form; shown when currentUser is null
    â”œâ”€â”€ AppHeader.vue           â€” sticky header, clock, New Task / Reminders / Settings / notification bell / user chip / logout
    â”œâ”€â”€ ToastContainer.vue      â€” toast notification list
    â”œâ”€â”€ StatsBar.vue            â€” total / open / overdue stats cards + members chip
    â”œâ”€â”€ TabBar.vue              â€” board / list / chat / reminders / activity log tabs + filters; activity tab admin-only
    â”œâ”€â”€ BoardView.vue           â€” kanban columns, drag-and-drop orchestration
    â”œâ”€â”€ TaskCard.vue            â€” individual kanban card (draggable); shows PENDING badge for unconfirmed tasks
    â”œâ”€â”€ ListView.vue            â€” sortable table view; shows PENDING badge for unconfirmed tasks
    â”œâ”€â”€ RemindersView.vue       â€” reminders tab list
    â”œâ”€â”€ ChatView.vue            â€” workspace group chat view (message list + composer)
    â”œâ”€â”€ ActivityLogView.vue     â€” paginated activity log table (admin only); fetches own data from Supabase
    â”œâ”€â”€ AddTaskModal.vue        â€” new task form; shows confirmation notice when user assigns to another member
    â”œâ”€â”€ AddReminderModal.vue    â€” new reminder form modal
    â”œâ”€â”€ TaskDetailModal.vue     â€” task detail with inline edit (restricted), comments section, PENDING badge
    â”œâ”€â”€ AddMemberModal.vue      â€” add member form (name, job role, email, password, access, colour); admin only
    â”œâ”€â”€ NotificationPanel.vue   â€” dropdown panel showing per-user notifications; accept/decline assignment requests
    â””â”€â”€ SettingsSidebar.vue     â€” right-side settings panel; content is role-gated (see below)

supabase/
â”œâ”€â”€ schema.sql                  â€” full schema for a fresh DB setup
â””â”€â”€ migrations/
    â”œâ”€â”€ 001_add_member_access.sql                  â€” adds access column (admin|user) to members
    â”œâ”€â”€ 002_add_member_credentials.sql             â€” adds email and password columns to members
    â”œâ”€â”€ 003_dynamic_task_statuses.sql              â€” drops status check constraint; creates task_statuses table
    â”œâ”€â”€ 004_activity_comments_notifications.sql    â€” adds confirmed to tasks; creates task_comments, activity_logs, notifications tables
    â”œâ”€â”€ 005_workspace_ownership.sql                â€” adds workspaces + workspace_members and scopes core tables
    â”œâ”€â”€ 006_done_status_config.sql                 â€” adds task_statuses.is_done for configurable done state
    â”œâ”€â”€ 007_workspace_chat.sql                     â€” adds workspace_messages + workspace_chat_reads and chat realtime publication
    â””â”€â”€ 008_workspace_chat_replies.sql             â€” adds `workspace_messages.reply_to_message_id` for chat reply threading
```

### Auth flow

The app uses a simple custom auth layer â€” **no Supabase Auth**. Credentials are stored in the `members` table.

1. On load, `currentUser` is `null` â†’ `LoginView` is rendered full-screen.
2. User submits email + password â†’ `login()` queries `members` where `email = X AND password = Y`.
3. On match, `currentUser` is set to the mapped member object, saved to `localStorage`, and `startApp()` is called.
4. On reload, `onMounted` reads `localStorage` and restores the session automatically.
5. Logout clears `currentUser` and `localStorage`, stops intervals, resets all state refs.
6. No registration UI â€” accounts are pre-created by an admin in the Settings sidebar.

### Role-based access

| Feature | `admin` | `user` |
|---|---|---|
| New Task | âœ… | âœ… (self only without confirmation; others require assignee confirmation) |
| Reminders | âœ… | âœ… |
| Edit / Delete task | âœ… (any task) | âœ… (own assigned tasks only) |
| Drag task to new column | âœ… (any task) | âœ… (own assigned tasks only) |
| Mark task as done | âœ… (any task) + notifies assignee | âœ… (own tasks only) |
| Reopen task (mark undone) | âœ… (any task) + notifies assignee | âœ… own task; sends `task_reopen_request` for others |
| Activity Log tab | âœ… | âœ— |
| Settings â†’ Members tab | âœ… | âœ— |
| Settings â†’ Task Statuses tab | âœ… | âœ— |
| Settings â†’ Appearance (theme) | âœ… | âœ… |
| Settings â†’ Change Password | âœ… (via Members tab) | âœ… (only option shown) |
| Add Member modal | âœ… | âœ— |

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
| `fetchWorkspaceMessages(workspaceId)` | Fetches latest 100 workspace chat messages (DESC in DB), then reverses client-side for oldest → newest rendering |
| `fetchChatReadState(workspaceId, memberId)` | Fetches chat read cursor (`last_read_at`) for unread count calculation |
| `fetchTasks()` | Fetches all tasks; available for manual refresh if needed |
| `startRealtimeSync()` | Opens three Supabase Realtime WebSocket channels: `db-tasks`, `db-notifications`, and `db-workspace-messages` (workspace-scoped). Patches local arrays in-place |
| `stopRealtimeSync()` | Removes all active Realtime channels |
| `notifyAdmins(type, message, taskId)` | Bulk-inserts a notification row for every admin except the current user |
| `applyTheme(dark)` | Sets `data-theme` attribute on `<html>` to `'dark'` or `'light'` |
| `toggleTheme()` | Flips `isDark`, calls `applyTheme`, persists to `localStorage` as `squad_theme` |
| `logActivity(action, entityType, entityId, message)` | Inserts a row into `activity_logs`; called after every state-changing action |
| `addTask()` | Insert task; if `user` role assigns to another member â†’ `confirmed = false` + sends `task_assignment_request` to assignee + notifies admins; otherwise sends `task_assigned` to assignee + notifies admins |
| `editTask({ id, title, desc, priority, due, status })` | Updates task fields; guarded â€” non-admin non-assignee gets error toast and early return |
| `onCommentAdded({ taskId, taskTitle })` | Logs `task_commented` activity; if actor is a user role, notifies all admins via `notifyAdmins` |
| `toggleDone(id)` | Permission-gated: admin â†’ immediate + notifies assignee; own task â†’ immediate; user marking other's done â†’ blocked; user reopening other's task â†’ sends `task_reopen_request` to assignee |
| `deleteTask(id)` | Delete task + linked reminders locally and in DB; logs activity |
| `addReminder()` | Insert standalone reminder; logs activity |
| `deleteReminder(id)` | Delete reminder |
| `addMember()` | Insert new member; logs activity |
| `updateMember({ id, â€¦ })` | Update member fields; syncs `currentUser` if self-update |
| `deleteMember(id)` | Delete member; logs activity |
| `updateColumn / addStatus / deleteStatus` | Manage `task_statuses` rows |
| `reorderColumn(status, direction)` | Reorder kanban columns: swaps positions and renumbers all `sort_order` values sequentially (0, 1, 2...); direction is 'up' or 'down'; shows success toast on completion |
| `onDrop(status)` | Kanban drag-and-drop; guarded â€” non-admin non-assignee blocked; logs activity; notifies admins if actor is user role |
| `sendWorkspaceMessage(content)` | Sends a workspace chat message with validation (`trim`, max 2000 chars), appends locally, logs activity |
| `markChatRead()` | Updates `workspace_chat_reads.last_read_at` when user is on Chat tab |
| `markAllNotificationsRead()` | Marks all unread notifications as read in DB and local ref |
| `acceptAssignment(notif)` | Sets `task.confirmed = true`; deletes request notification; sends `task_confirmed` to sender |
| `declineAssignment(notif)` | Deletes the task and notification; sends `task_declined` to sender |
| `acceptReopenRequest(notif)` | Reopens the task (done=false, moves to first column); deletes request notification; sends `task_reopen_accepted` to sender |
| `declineReopenRequest(notif)` | Deletes the request notification; sends `task_reopen_declined` to sender |

### Component contract

- **Props down, events up.** `App.vue` passes state as props; components emit named events back.
- `currentUser` is passed as a prop to `AppHeader`, `AddTaskModal`, `TaskDetailModal`, `TabBar`, `BoardView`, `ListView`, and `SettingsSidebar` to drive role-gated UI and permission checks.
- `TaskDetailModal` and `ActivityLogView` call Supabase **directly** for their scoped data (comments, activity logs) â€” this is intentional to keep App.vue lean. All other DB writes go through App.vue actions.
- `columns` is passed as a prop to `BoardView`, `ListView`, `AddTaskModal`, `TaskDetailModal`, and `SettingsSidebar`.
- `isDark` is passed to `SettingsSidebar`; theme is toggled via `toggle-theme` emit back to `App.vue`.

### `src/utils.js` exports

| Export | Purpose |
|---|---|
| `uid()` | Random string ID â€” used for toast IDs only |
| `priorityDotColor(p)` | Returns CSS colour for a priority level |
| `isOverdue(task)` | Returns `true` if task has a past due date and is not done |
| `dotToBadgeStyle(dot)` | Returns inline style object `{ background, color, border }` for dynamic status badges |
| `labelToKey(label)` | Slugifies a label to a DB-safe status key: `"In Review"` â†’ `"in_review"` |

### LoginView

- Full-screen centred card shown when `currentUser === null`.
- Accepts `error` (string) and `loading` (boolean) props; emits `login` with `{ email, password }`.
- No registration link â€” accounts are created by an admin.

### AppHeader

- Accepts `clock`, `currentUser`, `unreadCount`, `chatUnreadCount` props; emits `open-modal`, `open-settings`, `open-chat`, `open-notifications`, `logout`.
- Notification bell shows a red badge when `unreadCount > 0`; clicking emits `open-notifications` which toggles `showNotifications` in App.vue.
- Chat button shows a blue badge when `chatUnreadCount > 0`; clicking emits `open-chat` which switches `currentTab` to `chat`.
- Logout button emits `logout`.

### TaskDetailModal

- Accepts `open`, `task`, `members`, `columns`, `currentUser` props.
- Emits `close`, `toggle-done`, `delete-task`, `edit-task`, `comment-added`.
- **Edit button** shown only when `currentUser.access === 'admin' || task.assigneeId === currentUser.id`. Clicking populates an inline edit form (title, desc, priority, due, status).
- **Mark Done / Reopen button** gated by the same `canEdit` computed â€” hidden for non-owners.
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
| `task_assigned` | `assignment_ind` | blue | â€” |
| `task_assignment_request` | `assignment_late` | accent yellow | âœ… |
| `task_confirmed` | `check_circle` | teal | â€” |
| `task_declined` | `cancel` | red | â€” |
| `task_commented` | `chat_bubble` | gray | â€” |
| `task_status_changed` | `swap_horiz` | blue | â€” |
| `task_reopen_request` | `refresh` | accent yellow | âœ… |
| `task_reopen_accepted` | `check_circle` | teal | â€” |
| `task_reopen_declined` | `cancel` | red | â€” |
| `task_marked_done` | `task_alt` | blue | â€” |
| `task_reopened` | `replay` | blue | â€” |

- Unread notifications have an accent dot and a highlighted background.

### ActivityLogView

- Admin-only tab rendered when `currentTab === 'activity'`.
- Fetches its own data directly from Supabase using a join on `actor_id â†’ members`.
- Paginated: 20 entries per page, oldest-first within page, newest pages first overall.
- Has a Refresh button and Prev/Next pagination controls.

### AddTaskModal

- Accepts `currentUser` prop.
- When `currentUser.access === 'user'` and `form.assigneeId !== currentUser.id`, shows an inline notice: "The assignee will receive a notification to confirm this task."

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
  - composer shows a compact "Replying to â€¦" bar with cancel
  - replied messages render compact parent-message preview in the timeline
- Admin moderation:
  - admins can delete individual messages
  - admins can delete all chat messages in the current workspace
  - destructive actions require confirmation prompts

### SettingsSidebar

- Accepts `isDark` (Boolean) prop in addition to existing props.
- **Appearance section** â€” shown to all users at the top of the scrollable body. Displays current theme name and a toggle button (`light_mode` / `dark_mode` icon). Emits `toggle-theme`.
- **Admin view:** Members tab + Task Statuses tab (below Appearance section).
- **User view:** Change Password form (below Appearance section).
- **Task Statuses tab:** Each status row has up/down arrow buttons for reordering. Buttons are disabled (dimmed) for the first and last columns. Emits `reorder-status` with the status key and direction ('up' or 'down').
- Emits: `close`, `open-add-member`, `update-member`, `delete-member`, `update-status`, `add-status`, `delete-status`, `reorder-status`, `toggle-theme`.

### BoardView

- Accepts `currentUser` prop (in addition to existing props).
- `canDrag(task)` helper â€” returns `true` when `currentUser.access === 'admin'` or `task.assigneeId === currentUser.id`.
- Passes `:can-drag="canDrag(task)"` to each `TaskCard`.
- Includes a fixed **Back to Top** button that appears after vertical scrolling and smoothly scrolls `window` to top.

### TaskCard / ListView

- Both show an orange **PENDING** badge when `task.confirmed === false`.
- **`TaskCard`** â€” accepts `canDrag` (Boolean, default `true`) prop. `:draggable="canDrag"`. Checkbox click blocked (dimmed, `cursor: not-allowed`) when `canDrag` is false.
- **`ListView`** â€” accepts `currentUser` prop. `canAct(task)` helper gates the checkbox the same way.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root` (dark defaults).
- **Light mode** â€” `[data-theme="light"]` block in `style.css` overrides all 9 CSS variables. `applyTheme(dark)` sets `data-theme` on `<html>`. Targeted overrides for noise opacity, select option background, modal backdrop, card/toast shadows, drag-over tint, and ghost button hover.
- Status badge colours derived at runtime via `dotToBadgeStyle(dot)`.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).
- Icons: **Google Material Icons** via CDN. Use `<span class="material-icons">icon_name</span>` â€” no emoji.

### Key behaviours

- **Auth gate** â€” `LoginView` shown via `v-if="!currentUser"`. Full app in `<template v-else>`. No data fetched until login succeeds.
- **Session persistence** â€” `currentUser` saved to `localStorage` on login; restored in `onMounted` to survive page reloads.
- **Workspace persistence** â€” `currentWorkspaceId` is restored from `localStorage` (`squad_workspace`) on reload, and `sessionWorkspaceChosen` is restored to avoid re-opening `WorkspaceGateView` after refresh.
- **Theme persistence** â€” `isDark` initialised from `localStorage` key `squad_theme`. Applied to `<html data-theme>` immediately in `onMounted` before first render.
- **Task confirmation** â€” tasks with `confirmed = false` are created by non-admin users assigning to others. They show a PENDING badge everywhere and block action buttons in the detail modal. Assignee accepts/declines via `NotificationPanel`.
- **Permission enforcement** â€” all mutating actions (`editTask`, `onDrop`, `toggleDone`) guard at the action level in `App.vue` in addition to UI-level gating. Non-owner non-admin calls return early with an error toast.
- **Reopen approval flow** â€” when a `user` tries to reopen a task assigned to someone else, a `task_reopen_request` notification is sent to the assignee with Accept/Decline buttons. Admin reopens bypass the flow and notify the assignee directly.
- **Admin activity notifications** â€” `notifyAdmins()` sends notifications to all admins when a user role: comments on a task (`task_commented`), assigns a task to someone (`task_assigned`), or moves a task to a new status (`task_status_changed`).
- **Edit restriction** â€” Edit, Delete, and Mark Done buttons in `TaskDetailModal` only render when `currentUser.access === 'admin' || task.assigneeId === currentUser.id`.
- **Activity logging** â€” `logActivity()` is called after every significant action. Logs are never deleted (no cap). The Activity Log view paginates them.
- **Chat** â€” workspace group chat is realtime via `workspace_messages`; unread count is computed from `workspace_chat_reads.last_read_at` and excludes self-sent messages.
- **Chat hydration fallback** â€” entering Chat tab triggers a fresh message + read-state fetch so members can always see history even if realtime misses prior inserts.
- **Realtime sync** â€” after workspace selection, `startRealtimeSync()` opens three Realtime channels: tasks, notifications, and workspace chat messages. Requires `tasks`, `notifications`, and `workspace_messages` to be in `supabase_realtime`.
- **Reload hydration** â€” when a saved workspace exists, startup now fetches full workspace data and starts realtime immediately (without requiring a manual workspace switch).
- **Reminder interval** â€” still runs every 15 s but now only checks for due reminders; no longer fetches tasks or notifications.
- **Tab views** use `v-if` â€” no entry animations on per-item elements (causes flicker on tab switch).
- **Drag-and-drop** â€” native HTML5 events. `dragTaskId` tracks in-flight card; `dragOver` drives highlight. Cards are non-draggable (`:draggable="false"`) for tasks the current user does not own. Status change logged after drop.
- **Optimistic updates** â€” all actions mutate local refs immediately, then write to Supabase. Errors surface as red toasts.
- **Dynamic statuses** â€” no DB check constraint on `tasks.status`. Valid keys are whatever rows exist in `task_statuses`.
- **Self-update sync** â€” `updateMember` patches `currentUser` when the updated member is the logged-in user.

### Data flow

```
user action (component event)
  â†’ App.vue handler mutates tasks / reminders / members / columns / notifications / chatMessages refs
  â†’ computed filteredTasks / unreadCount / chatUnreadCount update automatically
  â†’ props re-render BoardView / ListView / ChatView / StatsBar / SettingsSidebar / AppHeader
```

State is persisted in **Supabase Postgres**. See [SUPABASE.md](./SUPABASE.md) for full database documentation.


### Latest updates (v3.12.4)

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

