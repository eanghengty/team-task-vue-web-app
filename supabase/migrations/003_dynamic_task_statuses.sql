-- Remove hardcoded status check constraint so statuses can be managed dynamically
alter table tasks drop constraint if exists tasks_status_check;

-- Table that drives the kanban columns
create table task_statuses (
  id         uuid primary key default gen_random_uuid(),
  key        text not null unique,
  label      text not null,
  dot        text not null default '#888888',
  sort_order int  not null default 0,
  created_at timestamptz not null default now()
);

-- Seed with the four original statuses
insert into task_statuses (key, label, dot, sort_order) values
  ('todo',     'Todo',        '#888888', 0),
  ('progress', 'In Progress', '#e8ff47', 1),
  ('review',   'Review',      '#47c5ff', 2),
  ('done',     'Done',        '#444444', 3);

alter table task_statuses enable row level security;
create policy "allow all task_statuses" on task_statuses for all using (true) with check (true);
