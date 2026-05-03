-- Add access role to members (admin | user)
alter table members
  add column if not exists access text not null default 'user'
    check (access in ('admin', 'user'));
