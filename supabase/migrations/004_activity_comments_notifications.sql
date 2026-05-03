-- confirmed flag: false = pending assignee acceptance (only set by non-admin cross-assignment)
alter table tasks add column if not exists confirmed boolean not null default true;

-- comments on tasks
create table if not exists task_comments (
  id         uuid        primary key default gen_random_uuid(),
  task_id    uuid        not null references tasks(id) on delete cascade,
  member_id  uuid        references members(id) on delete set null,
  content    text        not null,
  created_at timestamptz not null default now()
);

-- activity log (no cap, paginated in UI)
create table if not exists activity_logs (
  id          uuid        primary key default gen_random_uuid(),
  actor_id    uuid        references members(id) on delete set null,
  action      text        not null,
  entity_type text        not null default 'task',
  entity_id   text,
  message     text        not null,
  created_at  timestamptz not null default now()
);

-- per-member notifications
create table if not exists notifications (
  id         uuid        primary key default gen_random_uuid(),
  member_id  uuid        not null references members(id) on delete cascade,
  sender_id  uuid        references members(id) on delete set null,
  type       text        not null,
  message    text        not null,
  task_id    uuid        references tasks(id) on delete cascade,
  read       boolean     not null default false,
  created_at timestamptz not null default now()
);

-- RLS open dev policies
alter table task_comments enable row level security;
alter table activity_logs  enable row level security;
alter table notifications  enable row level security;

create policy "allow all task_comments" on task_comments for all using (true) with check (true);
create policy "allow all activity_logs" on activity_logs  for all using (true) with check (true);
create policy "allow all notifications" on notifications  for all using (true) with check (true);
