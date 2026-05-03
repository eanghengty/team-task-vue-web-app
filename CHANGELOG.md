# Changelog

All notable changes to SQUAD — Team Task Board.

## [3.3.0] — 2026-05-03

### Changed
- **Task statuses are now fully dynamic.** The hardcoded `CHECK (status IN ('todo','progress','review','done'))` constraint has been removed from `tasks.status`. Valid statuses are whatever rows exist in the new `task_statuses` table.
- `columns` ref in `App.vue` is now loaded from `task_statuses` on mount instead of being a hardcoded array.
- `toggleDone` now resolves the "done" column as the **last** row by `sort_order` and the "first" column as the first row — no longer hardcoded to `'done'` / `'todo'`.
- `form.status` default is set to the first column key after `fetchAll()` completes.
- `updateColumn` now persists label and dot colour changes to `task_statuses` in Supabase (previously in-memory only).
- Status badges in `BoardView`, `ListView`, and `TaskDetailModal` now use `dotToBadgeStyle(dot)` inline styles instead of fixed CSS badge classes (`badge-yellow`, `badge-blue`, etc.).
- `AddTaskModal` status `<select>` is now `v-for` over the `columns` prop — options update automatically when statuses change.
- `columns` prop added to `ListView`, `AddTaskModal`, and `TaskDetailModal` so all status label/colour resolution is dynamic.

### Added
- `task_statuses` Supabase table: `key`, `label`, `dot`, `sort_order`. Seeded with the 4 original statuses.
- `addStatus({ label, dot })` action in `App.vue` — inserts a new `task_statuses` row; key auto-generated from label via `labelToKey()`.
- `deleteStatus(status)` action in `App.vue` — deletes the row; blocked with a red toast if any tasks still use that status key.
- `mapStatus(row)` mapper in `App.vue` — translates `task_statuses` snake_case to camelCase JS shape.
- `dotToBadgeStyle(dot)` helper in `src/utils.js` — converts a hex dot colour to an inline badge style object.
- `labelToKey(label)` helper in `src/utils.js` — slugifies a label to a DB-safe key (`"In Review"` → `"in_review"`).
- **Settings sidebar — Task Statuses tab** now supports:
  - **Add Status** — inline form with colour picker and label input; key previewed in real time.
  - **Delete Status** — per-row delete button; blocked if tasks are currently using that status.

### Removed
- `statusLabel()` and `statusBadgeClass()` from `src/utils.js` — replaced by dynamic column lookups.
- `badgeClass` field from the `columns` shape — badge appearance is now derived from `dot` at runtime.
- DB check constraint on `tasks.status` (migration `003`).

### DB
- Migration `003_dynamic_task_statuses.sql` applied.

---

## [3.2.0] — 2026-05-03

### Added
- **Email and password fields on members** — stored in Supabase. Added to the Add Member modal and the Settings sidebar.
- `AddMemberModal` now includes: Email (text input), Password (show/hide toggle), and Access (admin/user dropdown) fields.
- **Settings sidebar — Members tab** view state now shows email (with mail icon) and masked password (with reveal/hide toggle) for each member.
- Edit state in the Members tab includes email and password fields — password field left blank preserves the existing password.
- `updateMember` in `App.vue` only patches the password column when the edit form's password field is non-empty.
- `memberForm` in `App.vue` gains `email`, `password`, and `access` fields.
- DB migration `002_add_member_credentials.sql`: adds `email text unique` and `password text` to `members`.

---

## [3.1.0] — 2026-05-03

### Added
- **Settings sidebar** — right-side sliding panel (`width: 440px`, `z-[260]`) opened via the Settings button in the header.
  - **Members tab** — view all members with avatar, job role, and access badge (admin/user). Inline-edit name, job role, colour, and access role. Delete members directly from settings. "+ Add Member" shortcut opens the existing modal.
  - **Task Statuses tab** — view all kanban statuses with dot colour and live task count. Inline-edit labels and dot colours.
- `access` field on members (`admin | user`, default `user`) — persisted in Supabase.
- `updateMember`, `deleteMember` actions in `App.vue`.
- `updateColumn` action mutates the `columns` ref (in-memory at this version — persisted to DB from v3.3.0).
- `showSettings` ref in `App.vue` controls sidebar visibility.
- Settings button added to `AppHeader.vue`.
- Supabase CLI installed as a dev dependency (`supabase` package). npm scripts added: `db:login`, `db:link`, `db:push`, `db:pull`, `db:diff`, `db:reset`, `db:types`.
- DB migration `001_add_member_access.sql` applied.

---

## [3.0.1] — 2026-05-03

### Fixed
- **401 Unauthorized on Supabase requests** — caused by pasting the wrong key type into `VITE_SUPABASE_ANON_KEY`. The correct key is the `anon public` JWT from Supabase → Project Settings → API. It starts with `eyJ` and is ~200 characters long. The `sb_secret_...` format is not a valid anon key.

---

## [3.0.0] — 2026-05-03

### Changed
- **Supabase backend.** All state (tasks, members, reminders) is now persisted in Supabase Postgres. Hardcoded seed data and in-memory-only state are removed.
- `App.vue` imports `supabase` from `src/lib/supabase.js` and calls `fetchAll()` on mount to load data from three tables: `members`, `tasks`, `reminders`.
- All actions (`addTask`, `toggleDone`, `deleteTask`, `addReminder`, `deleteReminder`, `addMember`, `onDrop`) now perform Supabase inserts/updates/deletes. Local state is updated optimistically; errors surface as red toasts.
- Reminder checker (`setInterval` 15 s) now persists `fired = true` back to Supabase.
- A loading spinner (Material Icon `refresh`) is shown while the initial fetch is in-flight.
- Snake_case DB columns are mapped to camelCase in JS via `mapTask`, `mapReminder`, `mapMember` helper functions.

### Added
- `src/lib/supabase.js` — Supabase client initialised from `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` env vars.
- `.env` — local env file (git-ignored) for Supabase credentials.
- `.env.example` — committed template showing required env vars.
- `.gitignore` — excludes `node_modules/`, `dist/`, `.env`, `*.local`.
- `supabase/schema.sql` — SQL to create `members`, `tasks`, `reminders` tables with RLS enabled and open dev policies.

### Removed
- Hardcoded seed members (`Alex Kim`, `Mara Singh`, `Jordan Lee`) and sample tasks/reminders from `onMounted`.
- `uid()` no longer used for task/member/reminder IDs — primary keys are now UUIDs generated by Postgres (`gen_random_uuid()`). `uid()` is retained for toast notification IDs only.

---

## [2.3.0] — 2026-05-03

### Fixed
- **Tab switching flicker** — inactive `.tab-btn` now carries `border: 1px solid transparent` so toggling the active state never adds/removes a pixel and causes a layout reflow.
- **Card re-animation on tab switch** — removed `fade-up` class from `TaskCard.vue` and `RemindersView.vue` list items. Because views are mounted with `v-if`, every tab switch was destroying and remounting components, causing all cards to re-run the slide-up animation and appear to flicker.

---

## [2.2.0] — 2026-05-03

### Changed
- **Replaced all emoji with Material Icons.** Added Google Material Icons stylesheet to `index.html`; all `✕` dismiss/delete buttons across `ToastContainer.vue`, `AddMemberModal.vue`, `TaskDetailModal.vue`, and `RemindersView.vue` now use `<span class="material-icons">close</span>`.
- Toast notification titles in `App.vue` stripped of emoji prefixes (`✅`, `⏰`, `🧑‍💼`) — titles are now plain text.

---

## [2.1.0] — 2026-05-03

### Changed
- **Split monolithic `src/App.vue` into 12 focused components** under `src/components/`.
- Extracted pure helper functions (`uid`, `statusLabel`, `statusBadgeClass`, `priorityDotColor`, `isOverdue`) into `src/utils.js`; imported where needed instead of being duplicated.
- `App.vue` is now a lean orchestrator (~130 lines) responsible only for state, actions, and lifecycle hooks.
- Component contract: props flow down from `App.vue`; components emit named events (`open-modal`, `toggle-done`, `delete-task`, `drop`, etc.) back up.
- `StatsBar` now computes its own derived stats (`openCount`, `overdueCount`, `progressPct`) from the `tasks` prop.
- `TabBar` exposes `v-model:currentTab`, `v-model:filterMember`, `v-model:filterPriority` for two-way binding.
- `BoardView` delegates card rendering to `TaskCard` and proxies drag events up to `App.vue`.

### Added
- `src/components/AppHeader.vue` — sticky header with clock and action buttons.
- `src/components/ToastContainer.vue` — toast list with dismiss emit.
- `src/components/StatsBar.vue` — stats cards and members chip.
- `src/components/TabBar.vue` — tab switcher and filter selects.
- `src/components/BoardView.vue` — kanban column layout and drag-and-drop.
- `src/components/TaskCard.vue` — draggable task card.
- `src/components/ListView.vue` — table view of tasks.
- `src/components/RemindersView.vue` — reminders tab.
- `src/components/AddTaskModal.vue` — new task form.
- `src/components/AddReminderModal.vue` — new reminder form.
- `src/components/TaskDetailModal.vue` — task detail and actions.
- `src/components/AddMemberModal.vue` — add member form.

---

## [2.0.0] — 2026-05-03

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

## [1.0.0] — 2026-05-03

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
