create table if not exists motivational_quotes (
  id         uuid primary key default gen_random_uuid(),
  quote      text not null unique,
  created_at timestamptz not null default now()
);

alter table motivational_quotes enable row level security;

drop policy if exists "allow all motivational_quotes" on motivational_quotes;
create policy "allow all motivational_quotes" on motivational_quotes for all using (true) with check (true);

insert into motivational_quotes (quote) values
  ('Small steps every day build big results.'),
  ('Progress over perfection, always.'),
  ('Done is better than waiting for perfect.'),
  ('Momentum starts with one focused action.'),
  ('Consistency beats intensity in the long run.'),
  ('Clear goals turn effort into impact.'),
  ('Discipline today creates freedom tomorrow.'),
  ('Teamwork turns hard work into shared wins.'),
  ('Keep moving - every task completed matters.'),
  ('Great outcomes come from steady execution.')
on conflict (quote) do nothing;
