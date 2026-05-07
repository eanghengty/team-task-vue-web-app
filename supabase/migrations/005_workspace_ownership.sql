-- workspace ownership and scoping
create table if not exists workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references members(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  member_id uuid not null references members(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (workspace_id, member_id)
);

alter table tasks add column if not exists workspace_id uuid references workspaces(id) on delete cascade;
alter table reminders add column if not exists workspace_id uuid references workspaces(id) on delete cascade;
alter table notifications add column if not exists workspace_id uuid references workspaces(id) on delete cascade;
alter table activity_logs add column if not exists workspace_id uuid references workspaces(id) on delete cascade;
alter table task_comments add column if not exists workspace_id uuid references workspaces(id) on delete cascade;

do $$
declare
  default_workspace_id uuid;
begin
  select id into default_workspace_id
  from workspaces
  order by created_at
  limit 1;

  if default_workspace_id is null then
    insert into workspaces (name, owner_id)
    values (
      'Main Workspace',
      (select id from members order by created_at limit 1)
    )
    returning id into default_workspace_id;
  end if;

  insert into workspace_members (workspace_id, member_id)
  select default_workspace_id, m.id
  from members m
  on conflict (workspace_id, member_id) do nothing;

  update tasks set workspace_id = default_workspace_id where workspace_id is null;
  update reminders set workspace_id = default_workspace_id where workspace_id is null;
  update notifications set workspace_id = default_workspace_id where workspace_id is null;
  update activity_logs set workspace_id = default_workspace_id where workspace_id is null;
  update task_comments set workspace_id = default_workspace_id where workspace_id is null;
end $$;

alter table tasks alter column workspace_id set not null;
alter table reminders alter column workspace_id set not null;
alter table notifications alter column workspace_id set not null;
alter table activity_logs alter column workspace_id set not null;
alter table task_comments alter column workspace_id set not null;

alter table workspaces enable row level security;
alter table workspace_members enable row level security;

create policy "allow all workspaces" on workspaces for all using (true) with check (true);
create policy "allow all workspace_members" on workspace_members for all using (true) with check (true);
