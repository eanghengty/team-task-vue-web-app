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

Single-page Vue 3 app (Composition API + `<script setup>`). All application logic lives in one file — **`src/App.vue`** — intentionally kept as a single component rather than split into sub-components.

### State model

| Ref | Shape | Purpose |
|-----|-------|---------|
| `tasks` | `{ id, title, desc, assigneeId, priority, due, status, done, createdAt }[]` | All tasks |
| `reminders` | `{ id, title, taskId, datetime, assigneeId, fired }[]` | Standalone + task-linked reminders |
| `members` | `{ id, name, role, color }[]` | Team members; seeded with 3 defaults |
| `modals` | reactive object | `add / reminder / detail / member` boolean flags |
| `form / remForm / memberForm` | reactive objects | Controlled inputs for each modal |

`status` is the source of truth for which Kanban column a task belongs to (`todo | progress | review | done`). `done` is a boolean mirror that is set `true` when status becomes `'done'` and cleared otherwise.

### Styling

- **Tailwind 3** utility classes + custom CSS in `src/style.css` via `@layer components`.
- CSS custom properties (`--accent`, `--surface`, `--border`, etc.) defined in `:root` are used throughout both the stylesheet and inline `:style` bindings in the template. Prefer inline style for one-off color references, `@layer components` for reusable patterns.
- Fonts: `Bebas Neue` (`.font-display`), `DM Mono` (`.font-mono`), `Space Grotesk` (default body).

### Key behaviours

- **Drag-and-drop** — native HTML5 drag events on `.task-card` / `.column`. `dragTaskId` ref tracks the in-flight card; `dragOver` ref drives the `.drag-over` highlight class.
- **Reminder checker** — `setInterval` every 15 s fires toasts for any reminder whose `datetime ≤ now` and `fired === false`, then marks `fired = true`.
- **Toasts** — managed as a `toasts` ref array. Each toast auto-removes after a configurable duration via `fading` flag + CSS `slideOut` animation.
- **Filters** (`filterMember`, `filterPriority`) are top-level refs; `filteredTasks` is a computed that both the board columns and list view derive from.

### Data flow

```
user action → mutate tasks/reminders/members refs
           → computed filteredTasks updates automatically
           → template re-renders (board columns, list, stats)
```

No Vuex/Pinia; no router; no external API calls. All state is in-memory and resets on page reload.
