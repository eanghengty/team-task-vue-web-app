-- Add login credentials to members
alter table members
  add column if not exists email    text unique,
  add column if not exists password text;
