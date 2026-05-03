# SUPABASE.md

Database documentation for SQUAD — Team Task Board.

## Initial setup

1. Go to [supabase.com](https://supabase.com), create a project.
2. Open the **SQL Editor** and run `supabase/schema.sql` to create all tables and policies.
3. Copy `.env.example` → `.env` and fill in the two variables:

```env
VITE_SUPABASE_URL=https://<your-project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...   # anon public JWT, ~200 chars
```

> The anon key comes from **Project Settings → API → Project API keys → anon public**.
> It starts with `eyJ`. The `sb_secret_...` format is the service role key — do **not** use it here; it will cause 401 errors.

4. `.env` is git-ignored. Never commit it.
5. Seed at least one `admin` member directly in the Supabase table editor (or via SQL) so there is an account to log in with:

```sql
insert into members (name, role, email, password, access, color)
values ('Your Name', 'Admin', 'you@example.com', 'yourpassword', 'admin', '#e8ff47');
```

---

## Authentication

The app does **not** use Supabase Auth. Login is a plain query against the `members` table:

```js
supabase.from('members').select('*').eq('email', email).eq('password', password).single()
```

- A successful match sets `currentUser` in `App.vue`, saves it to `localStorage`, and loads the app.
- On page reload, `onMounted` restores the session from `localStorage` — no re-login required.
- Passwords are stored **plaintext** — hash them (e.g. bcrypt) before going to production.
- There is no registration UI; all accounts are created by an admin in the Settings sidebar or directly in the DB.

---

## CLI workflow (no Supabase website needed)

The Supabase CLI is installed as a dev dependency (`supabase` package). Authenticate and link once, then use npm scripts for all DB work.

```bash
# One-time setup
npm run db:login   # opens browser OAuth flow
npm run db:link    # select your Supabase project from the list

# Day-to-day
npm run db:push    # apply pending migrations in supabase/migrations/ to the remote DB
npm run db:pull    # pull the current remote schema as a new migration file
npm run db:diff    # show what has changed since the last migration
npm run db:reset   # drop and recreate the DB, then re-run all migrations (destructive)
npm run db:types   # generate TypeScript types → src/types/supabase.ts
```

---

## Schema

### `members`

Stores team members. Also used as the login credential store.

| Column     | Type        | Default            | Notes                                                        |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                                                 |
| `name`       | `text`      | —                  | Required                                                     |
| `role`       | `text`      | `'Team Member'`    | Job title / role label                                       |
| `color`      | `text`      | `'#e8ff47'`        | Hex colour for avatar                                        |
| `access`     | `text`      | `'user'`           | `'admin'` or `'user'` — controls which UI features are visible |
| `email`      | `text`      | `null`             | Login email; unique across all members                       |
| `password`   | `text`      | `null`             | Login password — stored plaintext; hash before production    |
| `created_at` | `timestamptz` | `now()`          | Auto-set on insert                                           |

**Check constraint:** `access in ('admin', 'user')`

---

### `tasks`

| Column       | Type        | Default    | Notes                                                        |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                                         |
| `title`      | `text`      | —          | Required                                                     |
| `description`| `text`      | `''`       | Optional long-form text                                      |
| `assignee_id`| `uuid`      | `null`     | FK → `members(id)`, set null on member delete                |
| `priority`   | `text`      | `'medium'` | `'high'`, `'medium'`, or `'low'`                             |
| `due`        | `date`      | `null`     | Optional due date                                            |
| `status`     | `text`      | `'todo'`   | Free-text key matching a `task_statuses.key` — no check constraint |
| `done`       | `boolean`   | `false`    | Mirror of task being in the last status column               |
| `confirmed`  | `boolean`   | `true`     | `false` when a non-admin user assigns to another member; task becomes active on assignee acceptance |
| `created_at` | `timestamptz` | `now()`  | Auto-set on insert                                           |

**Check constraint:** `priority in ('high', 'medium', 'low')`

> Unconfirmed tasks (`confirmed = false`) are shown on the board and list with an orange **PENDING** badge. Action buttons are disabled in the detail modal until confirmed.

---

### `task_statuses`

Drives the kanban columns. Fully managed from the Settings sidebar (admin only).

| Column       | Type        | Default   | Notes                                                        |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                                         |
| `key`        | `text`      | —         | Unique slug stored in `tasks.status` (e.g. `in_review`)      |
| `label`      | `text`      | —         | Display name shown in the UI (e.g. `In Review`)              |
| `dot`        | `text`      | `'#888888'` | Hex colour for the status dot and badge                    |
| `sort_order` | `int`       | `0`       | Column order on the kanban board (ascending)                 |
| `created_at` | `timestamptz` | `now()` | Auto-set on insert                                           |

**Default rows (seeded by migration 003):**

| key | label | dot |
|---|---|---|
| `todo` | Todo | `#888888` |
| `progress` | In Progress | `#e8ff47` |
| `review` | Review | `#47c5ff` |
| `done` | Done | `#444444` |

> The **last** row by `sort_order` is treated as the "done" state by `toggleDone`.

---

### `reminders`

| Column       | Type        | Default    | Notes                                                        |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                                         |
| `title`      | `text`      | —          | Required                                                     |
| `task_id`    | `uuid`      | `null`     | FK → `tasks(id)`, set null on task delete                    |
| `datetime`   | `timestamptz` | —        | When the reminder fires                                      |
| `assignee_id`| `text`      | `'team'`   | Member id or `'team'` for a global reminder                  |
| `fired`      | `boolean`   | `false`    | Set `true` after toast is shown; persisted back to DB        |
| `created_at` | `timestamptz` | `now()`  | Auto-set on insert                                           |

---

### `task_comments`

Comments and progress updates on individual tasks. Visible to all members in the task detail modal.

| Column     | Type        | Default            | Notes                              |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                       |
| `task_id`    | `uuid`      | —                  | FK → `tasks(id)`, cascade delete  |
| `member_id`  | `uuid`      | `null`             | FK → `members(id)`, set null on member delete |
| `content`    | `text`      | —                  | Required                           |
| `created_at` | `timestamptz` | `now()`          | Auto-set on insert                 |

> Comments are fetched and inserted directly by `TaskDetailModal.vue` (not routed through App.vue).

---

### `activity_logs`

Append-only audit trail. No entries are ever deleted. Paginated in the Activity Log view (admin only, 20/page).

| Column      | Type        | Default            | Notes                                            |
|---|---|---|---|
| `id`          | `uuid`      | `gen_random_uuid()` | Primary key                                    |
| `actor_id`    | `uuid`      | `null`             | FK → `members(id)`, set null on member delete  |
| `action`      | `text`      | —                  | Machine-readable action key (e.g. `task_created`) |
| `entity_type` | `text`      | `'task'`           | `'task'`, `'member'`, `'reminder'`, etc.        |
| `entity_id`   | `text`      | `null`             | ID of the affected entity                       |
| `message`     | `text`      | —                  | Human-readable description shown in the UI      |
| `created_at`  | `timestamptz` | `now()`          | Auto-set on insert                              |

**Logged actions:** `task_created`, `task_updated`, `task_deleted`, `task_status_changed`, `task_commented`, `task_confirmed`, `task_declined`, `reminder_created`, `member_added`, `member_deleted`.

---

### `notifications`

Per-member notification inbox. Each member sees only their own notifications.

| Column     | Type        | Default    | Notes                                                            |
|---|---|---|---|
| `id`         | `uuid`      | `gen_random_uuid()` | Primary key                                           |
| `member_id`  | `uuid`      | —          | FK → `members(id)`, cascade delete — the recipient               |
| `sender_id`  | `uuid`      | `null`     | FK → `members(id)`, set null on delete — who triggered it        |
| `type`       | `text`      | —          | `task_assigned`, `task_assignment_request`, `task_confirmed`, `task_declined` |
| `message`    | `text`      | —          | Human-readable message shown in the panel                        |
| `task_id`    | `uuid`      | `null`     | FK → `tasks(id)`, cascade delete                                 |
| `read`       | `boolean`   | `false`    | Set `true` when user marks all read                              |
| `created_at` | `timestamptz` | `now()`  | Auto-set on insert                                               |

**Notification types:**

| Type | Trigger | Shown to |
|---|---|---|
| `task_assigned` | Admin or user assigns a confirmed task to someone | Assignee |
| `task_assignment_request` | Non-admin user assigns task to another member | Assignee; shows Accept/Decline buttons |
| `task_confirmed` | Assignee accepts a pending task | Original assigner |
| `task_declined` | Assignee declines a pending task | Original assigner |

---

## Row Level Security

RLS is enabled on all tables. Current policies are **open dev policies** allowing all operations:

```sql
create policy "allow all members"       on members       for all using (true) with check (true);
create policy "allow all tasks"         on tasks         for all using (true) with check (true);
create policy "allow all reminders"     on reminders     for all using (true) with check (true);
create policy "allow all task_statuses" on task_statuses for all using (true) with check (true);
create policy "allow all task_comments" on task_comments for all using (true) with check (true);
create policy "allow all activity_logs" on activity_logs for all using (true) with check (true);
create policy "allow all notifications" on notifications for all using (true) with check (true);
```

> Before going to production, replace with auth-scoped policies.

---

## Migrations

| File | Description |
|---|---|
| `001_add_member_access.sql` | Adds `access` column to `members` |
| `002_add_member_credentials.sql` | Adds `email` and `password` columns to `members` |
| `003_dynamic_task_statuses.sql` | Drops `tasks.status` check constraint; creates `task_statuses` table |
| `004_activity_comments_notifications.sql` | Adds `confirmed` to `tasks`; creates `task_comments`, `activity_logs`, `notifications` tables |

To add a new migration:

```bash
# Option A — write it manually
# Create supabase/migrations/005_your_change.sql, then:
npm run db:push

# Option B — make changes on a local Supabase instance and diff:
npm run db:diff   # generates a migration file automatically
npm run db:push   # apply it
```

---

## DB ↔ JS column mapping

| Table | DB column | JS field |
|---|---|---|
| `tasks` | `description` | `desc` |
| `tasks` | `assignee_id` | `assigneeId` |
| `tasks` | `confirmed` | `confirmed` |
| `tasks` | `created_at` | `createdAt` |
| `reminders` | `task_id` | `taskId` |
| `reminders` | `assignee_id` | `assigneeId` |
| `task_statuses` | `sort_order` | `sortOrder` |
| `task_statuses` | `key` | `status` |
| `notifications` | `member_id` | `memberId` |
| `notifications` | `sender_id` | `senderId` |
| `notifications` | `task_id` | `taskId` |
| `notifications` | `created_at` | `createdAt` |

All inserts use DB column names (`snake_case`). Mapper functions (`mapTask`, `mapMember`, `mapNotification`, etc.) in `App.vue` handle translation on every `select`.

---

## Client initialisation

`src/lib/supabase.js`:

```js
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
)
```

Import anywhere with:

```js
import { supabase } from '../lib/supabase.js'
```
