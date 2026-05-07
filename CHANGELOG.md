# Changelog

All notable changes to SQUAD â€” Team Task Board.

## [3.12.2] - 2026-05-07

### Added
- **BoardView fixed Back to Top button** for long board pages.
- Button appears after vertical scroll threshold and performs smooth scroll to the top of the page.

---

## [3.12.1] - 2026-05-07

### Fixed
- **Reload data hydration:** when a saved workspace is restored, startup now also fetches full workspace data and starts realtime immediately, so dashboard data is visible without manual workspace switching.
- **Chat visibility for workspace members:** entering the Chat tab now triggers an explicit message/read-state refresh, so members always see current chat history.
- **Chat history query correctness:** latest 100 messages are now fetched reliably (DESC query + client-side reverse for chronological rendering).

---

## [3.12.0] - 2026-05-07

### Added
- **Workspace member chat (v1)** with new `Chat` tab and `ChatView.vue` (workspace group channel, message list, composer).
- Header chat icon badge and Chat tab unread badge (`chatUnreadCount`).
- New Supabase migration: `007_workspace_chat.sql`.
- New tables:
  - `workspace_messages` (`workspace_id`, `sender_id`, `content`, `created_at`)
  - `workspace_chat_reads` (`workspace_id`, `member_id`, `last_read_at`)
- New chat realtime channel (`db-workspace-messages`) scoped by `workspace_id`.
- Chat actions in `App.vue`: `fetchWorkspaceMessages`, `fetchChatReadState`, `sendWorkspaceMessage`, `markChatRead`.
- Chat activity logging via `logActivity(... 'chat_message_sent' ...)`.

### Changed
- `startRealtimeSync()` now opens three channels: tasks, notifications, and workspace chat messages.
- `stopRealtimeSync()` now removes all three channels.
- `TabBar` now includes `Chat`; member/priority filters are hidden while Chat is active.

### Fixed
- **Workspace selection persistence on reload:** app now restores `currentWorkspaceId` and `sessionWorkspaceChosen` from `squad_workspace`, so refresh no longer re-opens workspace gate.
- **Header chat button wiring:** clicking chat icon now switches `currentTab` to `chat` (`open-chat` emit).

---

## [3.11.0] - 2026-05-07

### Fixed
- **Cross-workspace task move activity logging** now writes entries to both source and target workspace activity logs.

### Changed
- Added workspace-specific logging helper so activity can be inserted into an explicit workspace context.
- Admin task moves across workspaces now create `task_moved_workspace` activity entries in both workspaces.

---
## [3.10.0] - 2026-05-07

### Added
- **Admin cross-workspace task move** option in task edit (`TaskDetailModal`).
- Admin-only workspace selector in task edit mode.

### Changed
- `editTask` now supports moving tasks between workspaces for admins.
- When a task is moved to another workspace, linked reminders are moved to the same target workspace.
- After move, task/reminder rows are removed from the current workspace view and the detail modal closes to avoid stale context.

---
## [3.9.0] - 2026-05-07

### Added
- **Configurable done status** for task columns via `task_statuses.is_done`.
- New migration: `006_done_status_config.sql`.
- Admin control in Settings → Task Statuses to choose which status marks tasks as done/crossed.
- **Workspace-first full-page gate** after login (`WorkspaceGateView.vue`) before entering board/list/reminders/activity.

### Changed
- Done/reopen logic no longer assumes the last board column is done.
- Drag-and-drop done behavior now uses the configured done status.
- Reopen flow now uses the configured done status for resetting task state.
- Workspace owners (non-admin) can access Settings workspace management to add/remove workspace members.
- Post-login flow now requires explicit workspace selection/creation each session before app shell is shown.
- Saved workspace is only suggested in the gate; it does not auto-enter board view.
- App shell rendering is hard-gated until both conditions are true: workspace chosen in session + active workspace id.

### DB
- Added `task_statuses.is_done boolean not null default false`.
- Migration normalizes existing data so one done status is active (prefers `done` key).

---
## [3.8.0] - 2026-05-07

### Added
- **Workspace ownership model** with `workspaces` and `workspace_members` tables.
- New migration: `005_workspace_ownership.sql`.
- **Workspace switcher in header** so users can change active workspace context.
- **Create Workspace modal** (`AddWorkspaceModal.vue`) allowing any member to create a workspace; creator becomes owner.
- **Workspace management tab** in `SettingsSidebar` for admin/owner: rename workspace, add members, remove members.
- `App.vue` workspace actions: `fetchWorkspaces`, `fetchWorkspaceData`, `selectWorkspace`, `createWorkspace`, `updateWorkspace`, `addWorkspaceMember`, `removeWorkspaceMember`.

### Changed
- Data model now scopes operational entities by workspace:
  - `tasks`, `reminders`, `notifications`, `activity_logs`, `task_comments` now use `workspace_id`.
- Existing data is migrated into a default **Main Workspace** and all existing members are added to it.
- Board/List/Reminders/Notifications/Activity flows now run in the **current workspace context**.
- Realtime channels now filter by active workspace for `tasks`, and by both `member_id` + `workspace_id` for notifications.
- Activity log view and task comment queries are workspace-scoped.
- Task creation assignee options are workspace-aware (`workspaceAssignableMembers`).

### DB
- Updated `supabase/schema.sql` to include workspace-aware full schema.
- Added open-dev RLS policies for `workspaces` and `workspace_members`.

### Prerequisite
- Ensure Realtime publication includes workspace-scoped tables used by subscriptions:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  ```

---
## [3.7.0] â€” 2026-05-03

### Added
- **Column reordering in Task Statuses tab** â€” admins can now reorder kanban columns via up/down arrow buttons. Buttons are disabled (dimmed) for the first and last columns to prevent invalid moves. Reordering updates the `sort_order` field in the `task_statuses` table and immediately reflects on the board.
- `reorderColumn(status, direction)` action in `App.vue` â€” swaps column positions and renumbers all `sort_order` values sequentially to avoid database constraint violations. Shows a success toast on completion.
- Up/down arrow buttons in `SettingsSidebar` Task Statuses tab for each status row. Uses Material Icons `arrow_upward` and `arrow_downward`.
- `@reorder-status` event listener on `SettingsSidebar` component in App.vue.

### Changed
- `SettingsSidebar` emits `reorder-status` with status key and direction (up/down).

---

## [3.6.0] â€” 2026-05-03

### Added
- **Light / dark theme toggle** â€” `[data-theme="light"]` block in `style.css` overrides all CSS variables with warm off-white surfaces and a readable olive-lime accent (`#9db800`). `applyTheme(dark)` sets the attribute on `<html>`; `toggleTheme()` flips `isDark`, applies the theme, and persists the choice to `localStorage` as `squad_theme`. Preference is restored immediately in `onMounted` before first render.
- **Appearance section in SettingsSidebar** â€” shown to both admin and user at the top of the scrollable body. Displays current theme name and a toggle button with a `light_mode` / `dark_mode` Material icon. Emits `toggle-theme` to `App.vue`.
- **Permission enforcement at action level** â€” `editTask`, `onDrop`, and `toggleDone` in `App.vue` now guard with `if (currentUser.access !== 'admin' && task.assigneeId !== currentUser.id)` before any state mutation. Non-owner non-admin calls return early with a red toast. UI-level gates (disabled checkboxes, hidden buttons, non-draggable cards) remain as the first line of defence.
- **Drag permission on cards** â€” `BoardView` receives `currentUser` prop and computes `canDrag(task)`; passes `:can-drag` Boolean to each `TaskCard`. `TaskCard` uses `:draggable="canDrag"`; its checkbox also blocks click and dims (`opacity: 0.4`, `cursor: not-allowed`) when `canDrag` is false.
- **ListView permission** â€” `ListView` receives `currentUser` prop; `canAct(task)` helper gates the done checkbox the same way as `TaskCard`.
- **Mark Done gated by `canEdit`** â€” "Mark Done / Reopen" button in `TaskDetailModal` is now inside `v-if="task.confirmed !== false && canEdit"` so non-owners can no longer toggle done from the detail modal.
- **Reopen approval flow** â€” when a `user` role tries to reopen a task assigned to someone else, `toggleDone` sends a `task_reopen_request` notification to the assignee (with Accept / Decline buttons in `NotificationPanel`) instead of blocking outright. Admin reopens bypass the flow.
  - Assignee accepts â†’ task set to `done = false`, moved to first column if previously in done column; `task_reopen_accepted` notification sent to requester.
  - Assignee declines â†’ no state change; `task_reopen_declined` notification sent to requester.
- **Admin mark-done/reopen notifications** â€” when an admin toggles done on a task assigned to someone else, the assignee receives a `task_marked_done` or `task_reopened` notification instantly.
- **Admin activity notifications via `notifyAdmins()`** â€” helper bulk-inserts a notification for every admin (except the current user) when a `user` role performs: task comment (`task_commented`), task assignment to someone (`task_assigned`), or status change via drag (`task_status_changed`).
- **Supabase Realtime sync** â€” polling replaced with two persistent WebSocket channels opened by `startRealtimeSync()` after `fetchAll()`:
  - `db-tasks` â€” subscribes to all INSERT / UPDATE / DELETE on `tasks`; patches `tasks[]` in-place (no full array replacement). Open `detailTask` is also patched live on UPDATE.
  - `db-notifications` â€” subscribes to `notifications` filtered server-side to `member_id = currentUser.id`; new notifications are prepended instantly, capped at 50.
  - `stopRealtimeSync()` removes both channels on logout / unmount.
- **Realtime status logging** â€” `.subscribe()` callbacks log `[tasks channel] SUBSCRIBED` / `[notifications channel] SUBSCRIBED` (or errors) to the browser console for debugging.
- New notification types added to `NotificationPanel` icon/colour maps: `task_commented`, `task_status_changed`, `task_reopen_request`, `task_reopen_accepted`, `task_reopen_declined`, `task_marked_done`, `task_reopened`.
- `acceptReopenRequest(notif)` and `declineReopenRequest(notif)` actions added to `App.vue`.
- `App.vue` `@accept` / `@decline` event handlers on `NotificationPanel` now route by `notif.type` â€” `task_reopen_request` goes to the reopen handlers; everything else goes to the assignment handlers.
- `isDark` ref added to `App.vue` state (persisted as `squad_theme` in `localStorage`).

### Changed
- `startApp()` â€” no longer starts a notification/task poll; calls `startRealtimeSync()` after `fetchAll()` instead.
- `stopApp()` â€” calls `stopRealtimeSync()`.
- `logout()` â€” calls `stopRealtimeSync()` via `stopApp()`.
- Reminder interval â€” ticks every 15 s for reminder checks only; `fetchTasks()` and `fetchNotifications()` removed from the interval body.
- All manual `await fetchNotifications()` calls removed from action handlers (`acceptAssignment`, `declineAssignment`, `acceptReopenRequest`, `declineReopenRequest`, `toggleDone`) â€” realtime delivers those events automatically.
- `onDrop` â€” now uses column label (not raw key) in activity log and admin notification messages.
- `onCommentAdded` â€” made `async`; calls `notifyAdmins` when actor is a user role.
- `SettingsSidebar` â€” accepts `isDark` Boolean prop; emits `toggle-theme`; `.member-row:hover` border now uses `var(--muted)` instead of a hardcoded dark hex.
- `style.css` `.task-card:hover` border â€” uses `var(--muted)` instead of hardcoded `#3a3a3a` so it adapts to both themes.

### Prerequisite
- Run once in Supabase SQL editor to enable Realtime on the required tables:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  ```

---

## [3.5.0] â€” 2026-05-03

### Added
- **Task edit** â€” inline edit mode in `TaskDetailModal` (title, desc, priority, due, status). Edit button only rendered when `currentUser.access === 'admin'` or the task is assigned to the current user. Delete button follows the same restriction.
- **Activity log** â€” new `activity_logs` table (migration 004). Append-only; entries are never deleted. Admin-only **Activity Log tab** in `TabBar` renders `ActivityLogView.vue`, which fetches and paginates 20 entries per page with Prev/Next controls and a Refresh button. Actor name and avatar are joined server-side.
- **Task comments** â€” new `task_comments` table (migration 004). Comments section in `TaskDetailModal` shows all comments for the open task (fetched directly from Supabase, not routed through App.vue). All logged-in users can add a comment via text input (Enter or Send button). Intended for progress updates and obstacle notes. Adding a comment emits `comment-added` â†’ `App.vue` logs a `task_commented` activity entry.
- **Notification bell** â€” bell icon in `AppHeader` with a red unread-count badge driven by `unreadCount` computed. Clicking toggles `NotificationPanel`.
- **`NotificationPanel.vue`** â€” fixed dropdown below the bell, `z-[260]`. Lists last 50 notifications for the current user only. Shows actor icon, message, and timestamp. Unread rows have an accent dot. "Mark all read" button. Assignment request rows show **Accept** and **Decline** buttons.
- **`notifications` table** (migration 004) â€” per-member inbox with `member_id`, `sender_id`, `type`, `message`, `task_id`, `read`. Types: `task_assigned`, `task_assignment_request`, `task_confirmed`, `task_declined`.
- **Assignment confirmation flow** â€” when a `user` role creates a task assigned to another member, the task is saved with `confirmed = false` and a `task_assignment_request` notification is sent to the assignee. Admin-created tasks and self-assigned tasks are always `confirmed = true`.
  - Assignee accepts â†’ `confirmed = true`; `task_confirmed` notification sent to original assigner.
  - Assignee declines â†’ task deleted; `task_declined` notification sent to original assigner.
- **PENDING badge** â€” `TaskCard` and `ListView` both show an orange PENDING badge on tasks with `confirmed = false`. `TaskDetailModal` shows a pending warning banner and hides action buttons for unconfirmed tasks.
- **Cross-assignment notice** in `AddTaskModal` â€” inline info banner shown when a non-admin user selects an assignee other than themselves.
- `confirmed boolean default true` column added to `tasks` (migration 004).
- `fetchNotifications()` action in `App.vue` â€” fetches last 50 notifications for `currentUser`; called in `fetchAll()` and every 15 s in the reminder interval.
- `markAllNotificationsRead()`, `acceptAssignment(notif)`, `declineAssignment(notif)` actions in `App.vue`.
- `logActivity(action, entityType, entityId, message)` helper called after every significant action: task created/updated/deleted/status-changed/commented/confirmed/declined, reminder created, member added/deleted.
- `editTask({ id, â€¦ })` action in `App.vue` â€” updates task fields and logs activity.
- `onCommentAdded()` handler in `App.vue` â€” logs `task_commented` activity entry.
- `notifications` ref, `showNotifications` ref, `unreadCount` computed added to App.vue state.
- `mapNotification(row)` mapper added to App.vue.
- `confirmed` field added to `mapTask(row)`.
- `currentUser` prop added to `AddTaskModal`, `TaskDetailModal`, `TabBar`.
- `unreadCount` prop added to `AppHeader`.
- `NotificationPanel` imported and rendered in App.vue template.
- `ActivityLogView` imported and rendered in App.vue template when `currentTab === 'activity'`.

### Changed
- `TabBar` â€” accepts `currentUser` prop; Activity Log tab rendered only for admins.
- `AppHeader` â€” accepts `unreadCount` prop; emits `open-notifications`.
- `TaskDetailModal` â€” accepts `currentUser` prop; emits `edit-task`, `comment-added`; shows edit/delete buttons conditionally; shows PENDING badge and pending warning.
- `AddTaskModal` â€” accepts `currentUser` prop; shows cross-assignment confirmation notice.
- `TaskCard` â€” shows PENDING badge when `task.confirmed === false`.
- `ListView` â€” PENDING badge inline next to task title when `task.confirmed === false`.
- `onDrop` in App.vue â€” correctly derives `done` from the last column key rather than hardcoded `'done'` string; logs activity.
- `deleteTask` â€” logs `task_deleted` activity.
- `toggleDone` â€” logs `task_status_changed` activity.
- `addMember` / `deleteMember` â€” log activity.
- `addReminder` â€” logs activity.
- `logout()` â€” also clears `notifications` ref and `showNotifications`.
- Reminder interval â€” also calls `fetchNotifications()` on every tick.

### DB
- Migration `004_activity_comments_notifications.sql` applied.

---

## [3.4.0] â€” 2026-05-03

### Added
- **Login screen** (`LoginView.vue`) â€” full-screen centred card shown before the app loads. Email + password fields with show/hide toggle, Enter key support, and error display. No registration link.
- `currentUser` ref in `App.vue` â€” `null` when unauthenticated; set to the matched `members` row on login.
- `loginError` and `loginLoading` refs in `App.vue` â€” passed as props to `LoginView` to drive error and spinner state.
- `login({ email, password })` action â€” queries `members` table with `eq('email', â€¦).eq('password', â€¦).single()`; calls `startApp()` on success.
- `logout()` action â€” clears `currentUser`, stops clock + reminder intervals, resets all state refs.
- `startApp()` / `stopApp()` helpers â€” extracted from `onMounted` so the clock and reminder checker start after login and stop on logout.
- **Role-based UI gating:**
  - `admin` â€” full access (unchanged from v3.3.0).
  - `user` â€” New Task and Reminders buttons available; Settings shows only a Change Password form; Add Member modal is hidden.
- **Settings sidebar â€” user view** â€” no tabs; shows the logged-in user's avatar + email (read-only) and a Change Password form with new + confirm fields and match validation.
- **AppHeader** â€” logged-in user's colour avatar and name displayed next to the action buttons; logout button (Material Icon `logout`) emits `logout`.
- `currentUser` prop added to `AppHeader` and `SettingsSidebar`.
- **Self-update sync** â€” `updateMember` patches `currentUser` when the updated member is the logged-in user, keeping the header avatar/name live without requiring a re-login.

### Changed
- `App.vue` template restructured: `<LoginView v-if="!currentUser" â€¦>` / `<template v-else>` wraps the entire app.
- `fetchAll()`, clock interval, and reminder interval are no longer started in `onMounted` â€” they now start inside `startApp()` which is called after a successful login.
- `AddMemberModal` rendered with `v-if="currentUser.access === 'admin'"` â€” the component is not mounted at all for `user` role.
- `SettingsSidebar` tab nav rendered with `v-if="currentUser.access === 'admin'"` â€” users never see the Members or Task Statuses tabs.

## [3.3.0] â€” 2026-05-03

### Changed
- **Task statuses are now fully dynamic.** The hardcoded `CHECK (status IN ('todo','progress','review','done'))` constraint has been removed from `tasks.status`. Valid statuses are whatever rows exist in the new `task_statuses` table.
- `columns` ref in `App.vue` is now loaded from `task_statuses` on mount instead of being a hardcoded array.
- `toggleDone` now resolves the "done" column as the **last** row by `sort_order` and the "first" column as the first row â€” no longer hardcoded to `'done'` / `'todo'`.
- `form.status` default is set to the first column key after `fetchAll()` completes.
- `updateColumn` now persists label and dot colour changes to `task_statuses` in Supabase (previously in-memory only).
- Status badges in `BoardView`, `ListView`, and `TaskDetailModal` now use `dotToBadgeStyle(dot)` inline styles instead of fixed CSS badge classes (`badge-yellow`, `badge-blue`, etc.).
- `AddTaskModal` status `<select>` is now `v-for` over the `columns` prop â€” options update automatically when statuses change.
- `columns` prop added to `ListView`, `AddTaskModal`, and `TaskDetailModal` so all status label/colour resolution is dynamic.

### Added
- `task_statuses` Supabase table: `key`, `label`, `dot`, `sort_order`. Seeded with the 4 original statuses.
- `addStatus({ label, dot })` action in `App.vue` â€” inserts a new `task_statuses` row; key auto-generated from label via `labelToKey()`.
- `deleteStatus(status)` action in `App.vue` â€” deletes the row; blocked with a red toast if any tasks still use that status key.
- `mapStatus(row)` mapper in `App.vue` â€” translates `task_statuses` snake_case to camelCase JS shape.
- `dotToBadgeStyle(dot)` helper in `src/utils.js` â€” converts a hex dot colour to an inline badge style object.
- `labelToKey(label)` helper in `src/utils.js` â€” slugifies a label to a DB-safe key (`"In Review"` â†’ `"in_review"`).
- **Settings sidebar â€” Task Statuses tab** now supports:
  - **Add Status** â€” inline form with colour picker and label input; key previewed in real time.
  - **Delete Status** â€” per-row delete button; blocked if tasks are currently using that status.

### Removed
- `statusLabel()` and `statusBadgeClass()` from `src/utils.js` â€” replaced by dynamic column lookups.
- `badgeClass` field from the `columns` shape â€” badge appearance is now derived from `dot` at runtime.
- DB check constraint on `tasks.status` (migration `003`).

### DB
- Migration `003_dynamic_task_statuses.sql` applied.

---

## [3.2.0] â€” 2026-05-03

### Added
- **Email and password fields on members** â€” stored in Supabase. Added to the Add Member modal and the Settings sidebar.
- `AddMemberModal` now includes: Email (text input), Password (show/hide toggle), and Access (admin/user dropdown) fields.
- **Settings sidebar â€” Members tab** view state now shows email (with mail icon) and masked password (with reveal/hide toggle) for each member.
- Edit state in the Members tab includes email and password fields â€” password field left blank preserves the existing password.
- `updateMember` in `App.vue` only patches the password column when the edit form's password field is non-empty.
- `memberForm` in `App.vue` gains `email`, `password`, and `access` fields.
- DB migration `002_add_member_credentials.sql`: adds `email text unique` and `password text` to `members`.

---

## [3.1.0] â€” 2026-05-03

### Added
- **Settings sidebar** â€” right-side sliding panel (`width: 440px`, `z-[260]`) opened via the Settings button in the header.
  - **Members tab** â€” view all members with avatar, job role, and access badge (admin/user). Inline-edit name, job role, colour, and access role. Delete members directly from settings. "+ Add Member" shortcut opens the existing modal.
  - **Task Statuses tab** â€” view all kanban statuses with dot colour and live task count. Inline-edit labels and dot colours.
- `access` field on members (`admin | user`, default `user`) â€” persisted in Supabase.
- `updateMember`, `deleteMember` actions in `App.vue`.
- `updateColumn` action mutates the `columns` ref (in-memory at this version â€” persisted to DB from v3.3.0).
- `showSettings` ref in `App.vue` controls sidebar visibility.
- Settings button added to `AppHeader.vue`.
- Supabase CLI installed as a dev dependency (`supabase` package). npm scripts added: `db:login`, `db:link`, `db:push`, `db:pull`, `db:diff`, `db:reset`, `db:types`.
- DB migration `001_add_member_access.sql` applied.

---

## [3.0.1] â€” 2026-05-03

### Fixed
- **401 Unauthorized on Supabase requests** â€” caused by pasting the wrong key type into `VITE_SUPABASE_ANON_KEY`. The correct key is the `anon public` JWT from Supabase â†’ Project Settings â†’ API. It starts with `eyJ` and is ~200 characters long. The `sb_secret_...` format is not a valid anon key.

---

## [3.0.0] â€” 2026-05-03

### Changed
- **Supabase backend.** All state (tasks, members, reminders) is now persisted in Supabase Postgres. Hardcoded seed data and in-memory-only state are removed.
- `App.vue` imports `supabase` from `src/lib/supabase.js` and calls `fetchAll()` on mount to load data from three tables: `members`, `tasks`, `reminders`.
- All actions (`addTask`, `toggleDone`, `deleteTask`, `addReminder`, `deleteReminder`, `addMember`, `onDrop`) now perform Supabase inserts/updates/deletes. Local state is updated optimistically; errors surface as red toasts.
- Reminder checker (`setInterval` 15 s) now persists `fired = true` back to Supabase.
- A loading spinner (Material Icon `refresh`) is shown while the initial fetch is in-flight.
- Snake_case DB columns are mapped to camelCase in JS via `mapTask`, `mapReminder`, `mapMember` helper functions.

### Added
- `src/lib/supabase.js` â€” Supabase client initialised from `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` env vars.
- `.env` â€” local env file (git-ignored) for Supabase credentials.
- `.env.example` â€” committed template showing required env vars.
- `.gitignore` â€” excludes `node_modules/`, `dist/`, `.env`, `*.local`.
- `supabase/schema.sql` â€” SQL to create `members`, `tasks`, `reminders` tables with RLS enabled and open dev policies.

### Removed
- Hardcoded seed members (`Alex Kim`, `Mara Singh`, `Jordan Lee`) and sample tasks/reminders from `onMounted`.
- `uid()` no longer used for task/member/reminder IDs â€” primary keys are now UUIDs generated by Postgres (`gen_random_uuid()`). `uid()` is retained for toast notification IDs only.

---

## [2.3.0] â€” 2026-05-03

### Fixed
- **Tab switching flicker** â€” inactive `.tab-btn` now carries `border: 1px solid transparent` so toggling the active state never adds/removes a pixel and causes a layout reflow.
- **Card re-animation on tab switch** â€” removed `fade-up` class from `TaskCard.vue` and `RemindersView.vue` list items. Because views are mounted with `v-if`, every tab switch was destroying and remounting components, causing all cards to re-run the slide-up animation and appear to flicker.

---

## [2.2.0] â€” 2026-05-03

### Changed
- **Replaced all emoji with Material Icons.** Added Google Material Icons stylesheet to `index.html`; all `âœ•` dismiss/delete buttons across `ToastContainer.vue`, `AddMemberModal.vue`, `TaskDetailModal.vue`, and `RemindersView.vue` now use `<span class="material-icons">close</span>`.
- Toast notification titles in `App.vue` stripped of emoji prefixes (`âœ…`, `â°`, `ðŸ§‘â€ðŸ’¼`) â€” titles are now plain text.

---

## [2.1.0] â€” 2026-05-03

### Changed
- **Split monolithic `src/App.vue` into 12 focused components** under `src/components/`.
- Extracted pure helper functions (`uid`, `statusLabel`, `statusBadgeClass`, `priorityDotColor`, `isOverdue`) into `src/utils.js`; imported where needed instead of being duplicated.
- `App.vue` is now a lean orchestrator (~130 lines) responsible only for state, actions, and lifecycle hooks.
- Component contract: props flow down from `App.vue`; components emit named events (`open-modal`, `toggle-done`, `delete-task`, `drop`, etc.) back up.
- `StatsBar` now computes its own derived stats (`openCount`, `overdueCount`, `progressPct`) from the `tasks` prop.
- `TabBar` exposes `v-model:currentTab`, `v-model:filterMember`, `v-model:filterPriority` for two-way binding.
- `BoardView` delegates card rendering to `TaskCard` and proxies drag events up to `App.vue`.

### Added
- `src/components/AppHeader.vue` â€” sticky header with clock and action buttons.
- `src/components/ToastContainer.vue` â€” toast list with dismiss emit.
- `src/components/StatsBar.vue` â€” stats cards and members chip.
- `src/components/TabBar.vue` â€” tab switcher and filter selects.
- `src/components/BoardView.vue` â€” kanban column layout and drag-and-drop.
- `src/components/TaskCard.vue` â€” draggable task card.
- `src/components/ListView.vue` â€” table view of tasks.
- `src/components/RemindersView.vue` â€” reminders tab.
- `src/components/AddTaskModal.vue` â€” new task form.
- `src/components/AddReminderModal.vue` â€” new reminder form.
- `src/components/TaskDetailModal.vue` â€” task detail and actions.
- `src/components/AddMemberModal.vue` â€” add member form.

---

## [2.0.0] â€” 2026-05-03

### Changed
- **Full rewrite from single HTML file to Vue 3 + Tailwind CSS project.**
- Build tooling: Vite 5, `@vitejs/plugin-vue`, Tailwind 3, PostCSS, Autoprefixer.
- All inline `<script>` logic ported to Vue 3 Composition API (`<script setup>`) in `src/App.vue`.
- All inline `<style>` and CDN Tailwind replaced with `src/style.css` (`@layer components`) and a local Tailwind installation.
- Dev server fixed to port **6005** via `vite.config.js`.
- DOM manipulation (`innerHTML`, `getElementById`, `classList`) replaced with reactive refs, computed properties, and declarative template bindings.
- Drag-and-drop rewritten using Vue event handlers (`@dragstart`, `@dragover`, `@drop`) instead of global JS functions.
- Modals driven by a single `modals` reactive object instead of class toggling.
- Toast system rewritten as a `toasts` ref array rendered with `v-for` instead of imperative DOM insertion.
- Shake validation replaced with a `shaking` reactive object bound to CSS classes.
- Clock and reminder checker use `onMounted` / `onUnmounted` lifecycle hooks with proper cleanup.

### Removed
- CDN dependencies (`cdn.tailwindcss.com`, `moment.js` CDN, Google Fonts via HTML-only).
- All global JavaScript functions and direct DOM mutation.

---

## [1.0.0] â€” 2026-05-03

### Added
- Initial single-file HTML prototype (`team-taskboard.html`).
- Kanban board with four columns: Todo, In Progress, Review, Done.
- Task creation modal with title, description, assignee, priority, due date, status, and optional reminder.
- List view with sortable columns and inline done/delete actions.
- Reminder system with datetime picker, task linking, and auto-firing toast notifications.
- Add Member modal with name, role, and colour picker.
- Drag-and-drop between Kanban columns.
- Stats bar: total tasks, open, overdue, progress percentage.
- Member filter and priority filter.
- Live clock in header.
- Seeded sample data (3 members, 5 tasks, 1 reminder).




