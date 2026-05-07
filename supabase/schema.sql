-- SQUAD — Team Task Board
-- Run this in your Supabase SQL editor before starting the app.

create table members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  role       text not null default 'Team Member',
  color      text not null default '#e8ff47',
  access     text not null default 'user' check (access in ('admin', 'user')),
  email      text unique,
  password   text,
  created_at timestamptz not null default now()
);

create table workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  owner_id   uuid not null references members(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table workspace_members (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  member_id    uuid not null references members(id) on delete cascade,
  created_at   timestamptz not null default now(),
  unique (workspace_id, member_id)
);

create table task_statuses (
  id         uuid primary key default gen_random_uuid(),
  key        text not null unique,
  label      text not null,
  dot        text not null default '#888888',
  is_done    boolean not null default false,
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);

insert into task_statuses (key, label, dot, sort_order) values
  ('todo',     'Todo',        '#888888', 0),
  ('progress', 'In Progress', '#e8ff47', 1),
  ('review',   'Review',      '#47c5ff', 2),
  ('done',     'Done',        '#444444', 3);

update task_statuses set is_done = true where key = 'done';

create table tasks (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title        text not null,
  description  text not null default '',
  assignee_id  uuid references members(id) on delete set null,
  priority     text not null default 'medium' check (priority in ('high','medium','low')),
  due          date,
  status       text not null default 'todo',
  done         boolean not null default false,
  confirmed    boolean not null default true,
  created_at   timestamptz not null default now()
);

create table reminders (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  title        text not null,
  task_id      uuid references tasks(id) on delete set null,
  datetime     timestamptz not null,
  assignee_id  text not null default 'team',
  fired        boolean not null default false,
  created_at   timestamptz not null default now()
);

create table task_comments (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  task_id      uuid not null references tasks(id) on delete cascade,
  member_id    uuid references members(id) on delete set null,
  content      text not null,
  created_at   timestamptz not null default now()
);

create table activity_logs (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  actor_id     uuid references members(id) on delete set null,
  action       text not null,
  entity_type  text not null default 'task',
  entity_id    text,
  message      text not null,
  created_at   timestamptz not null default now()
);

create table notifications (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  member_id    uuid not null references members(id) on delete cascade,
  sender_id    uuid references members(id) on delete set null,
  type         text not null,
  message      text not null,
  task_id      uuid references tasks(id) on delete cascade,
  read         boolean not null default false,
  created_at   timestamptz not null default now()
);

-- Enable Row Level Security (configure policies to match your auth setup)
alter table members enable row level security;
alter table workspaces enable row level security;
alter table workspace_members enable row level security;
alter table tasks enable row level security;
alter table reminders enable row level security;
alter table task_statuses enable row level security;
alter table task_comments enable row level security;
alter table activity_logs enable row level security;
alter table notifications enable row level security;

-- Dev-only open policies — tighten these before going to production
create policy "allow all members" on members for all using (true) with check (true);
create policy "allow all workspaces" on workspaces for all using (true) with check (true);
create policy "allow all workspace_members" on workspace_members for all using (true) with check (true);
create policy "allow all tasks" on tasks for all using (true) with check (true);
create policy "allow all reminders" on reminders for all using (true) with check (true);
create policy "allow all task_statuses" on task_statuses for all using (true) with check (true);
create policy "allow all task_comments" on task_comments for all using (true) with check (true);
create policy "allow all activity_logs" on activity_logs for all using (true) with check (true);
create policy "allow all notifications" on notifications for all using (true) with check (true);

