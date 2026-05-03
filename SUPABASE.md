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

---

## CLI workflow (no Supabase website needed)

The Supabase CLI is installed as a dev dependency. Authenticate and link once, then use npm scripts for all DB work.

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

Stores team members. Referenced by `tasks.assignee_id`.

| Column | Type | Default | Notes |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | Primary key |
| `name` | `text` | — | Required |
| `role` | `text` | `'Team Member'` | Job title / role label |
| `color` | `text` | `'#e8ff47'` | Hex colour for avatar |
| `access` | `text` | `'user'` | `'admin'` or `'user'` — web access level |
| `created_at` | `timestamptz` | `now()` | Auto-set on insert |

**Check constraint:** `access in ('admin', 'user')`

---

### `tasks`

| Column | Type | Default | Notes |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | Primary key |
| `title` | `text` | — | Required |
| `description` | `text` | `''` | Optional long-form text |
| `assignee_id` | `uuid` | `null` | FK → `members(id)`, set null on member delete |
| `priority` | `text` | `'medium'` | `'high'`, `'medium'`, or `'low'` |
| `due` | `date` | `null` | Optional due date |
| `status` | `text` | `'todo'` | `'todo'`, `'progress'`, `'review'`, or `'done'` |
| `done` | `boolean` | `false` | Mirror of `status = 'done'`; kept in sync by app logic |
| `created_at` | `timestamptz` | `now()` | Auto-set on insert |

**Check constraints:**
- `priority in ('high', 'medium', 'low')`
- `status in ('todo', 'progress', 'review', 'done')`

---

### `reminders`

| Column | Type | Default | Notes |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | Primary key |
| `title` | `text` | — | Required |
| `task_id` | `uuid` | `null` | FK → `tasks(id)`, set null on task delete |
| `datetime` | `timestamptz` | — | When the reminder fires |
| `assignee_id` | `text` | `'team'` | Member id or `'team'` for a global reminder |
| `fired` | `boolean` | `false` | Set `true` after toast is shown; persisted back to DB |
| `created_at` | `timestamptz` | `now()` | Auto-set on insert |

---

## Row Level Security

RLS is enabled on all three tables. The current policies are **open dev policies** that allow all operations without authentication:

```sql
create policy "allow all members"   on members   for all using (true) with check (true);
create policy "allow all tasks"     on tasks     for all using (true) with check (true);
create policy "allow all reminders" on reminders for all using (true) with check (true);
```

> Before going to production, replace these with auth-scoped policies (e.g. `auth.uid() = assignee_id`).

---

## Migrations

Migrations live in `supabase/migrations/`. They are applied in filename order by `npm run db:push`.

| File | Description |
|---|---|
| `001_add_member_access.sql` | Adds `access text not null default 'user' check (access in ('admin','user'))` to `members` |

To add a new migration:

```bash
# Option A — write it manually
# Create supabase/migrations/002_your_change.sql and run:
npm run db:push

# Option B — make changes on a local Supabase instance and diff:
npm run db:diff   # generates a migration file automatically
npm run db:push   # apply it
```

---

## DB ↔ JS column mapping

Postgres uses `snake_case`; JS uses `camelCase`. Three mapper functions in `src/App.vue` handle the translation on every `select`:

| Table | DB column | JS field |
|---|---|---|
| `tasks` | `description` | `desc` |
| `tasks` | `assignee_id` | `assigneeId` |
| `tasks` | `created_at` | `createdAt` |
| `reminders` | `task_id` | `taskId` |
| `reminders` | `assignee_id` | `assigneeId` |

All inserts use the DB column names (`snake_case`).

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

Import it anywhere with:

```js
import { supabase } from '../lib/supabase.js'
```
