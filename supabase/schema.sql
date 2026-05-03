-- SQUAD — Team Task Board
-- Run this in your Supabase SQL editor before starting the app.

create table members (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  role       text not null default 'Team Member',
  color      text not null default '#e8ff47',
  created_at timestamptz not null default now()
);

create table tasks (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text not null default '',
  assignee_id uuid references members(id) on delete set null,
  priority    text not null default 'medium' check (priority in ('high','medium','low')),
  due         date,
  status      text not null default 'todo' check (status in ('todo','progress','review','done')),
  done        boolean not null default false,
  created_at  timestamptz not null default now()
);

create table reminders (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  task_id     uuid references tasks(id) on delete set null,
  datetime    timestamptz not null,
  assignee_id text not null default 'team',
  fired       boolean not null default false,
  created_at  timestamptz not null default now()
);

-- Enable Row Level Security (configure policies to match your auth setup)
alter table members  enable row level security;
alter table tasks    enable row level security;
alter table reminders enable row level security;

-- Dev-only open policies — tighten these before going to production
create policy "allow all members"   on members   for all using (true) with check (true);
create policy "allow all tasks"     on tasks     for all using (true) with check (true);
create policy "allow all reminders" on reminders for all using (true) with check (true);
