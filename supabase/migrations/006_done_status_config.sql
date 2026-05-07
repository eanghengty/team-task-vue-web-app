alter table task_statuses add column if not exists is_done boolean not null default false;

update task_statuses
set is_done = case when key = 'done' then true else false end
where not exists (select 1 from task_statuses where is_done = true);

-- Ensure only one done status is active after migration.
with ranked as (
  select id, row_number() over (order by case when key='done' then 0 else 1 end, sort_order, created_at) as rn
  from task_statuses
  where is_done = true
)
update task_statuses ts
set is_done = (r.rn = 1)
from ranked r
where ts.id = r.id;
