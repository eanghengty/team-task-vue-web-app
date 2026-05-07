-- Add profile picture URL support for members
alter table members
  add column if not exists avatar_url text;

