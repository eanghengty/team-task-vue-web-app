create table if not exists workspace_messages (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  sender_id    uuid references members(id) on delete set null,
  content      text not null check (char_length(trim(content)) > 0 and char_length(content) <= 2000),
  created_at   timestamptz not null default now()
);

create table if not exists workspace_chat_reads (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  member_id    uuid not null references members(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  unique (workspace_id, member_id)
);

alter table workspace_messages enable row level security;
alter table workspace_chat_reads enable row level security;

drop policy if exists "allow all workspace_messages" on workspace_messages;
create policy "allow all workspace_messages" on workspace_messages for all using (true) with check (true);

drop policy if exists "allow all workspace_chat_reads" on workspace_chat_reads;
create policy "allow all workspace_chat_reads" on workspace_chat_reads for all using (true) with check (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'workspace_messages'
  ) then
    alter publication supabase_realtime add table workspace_messages;
  end if;
end $$;
