-- Phase 3: build tracking columns (run after collection_items.sql)

alter table public.collection_items
  add column if not exists build_steps jsonb default '[]',
  add column if not exists build_logs jsonb default '[]',
  add column if not exists total_build_seconds double precision default 0,
  add column if not exists manual_book int default 1,
  add column if not exists manual_page int default 1,
  add column if not exists manual_step int default 1,
  add column if not exists manual_step_total int default 18;
