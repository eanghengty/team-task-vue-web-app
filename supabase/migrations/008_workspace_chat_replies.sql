alter table workspace_messages
add column if not exists reply_to_message_id uuid references workspace_messages(id) on delete set null;
