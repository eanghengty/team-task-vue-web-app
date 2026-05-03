# Changelog

All notable changes to SQUAD — Team Task Board.

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
