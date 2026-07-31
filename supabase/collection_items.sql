-- Run in Supabase SQL Editor (Phase 2: cloud sync for Pro users)

create table if not exists public.collection_items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  seed_kit_id text,
  name text not null,
  series text not null,
  grade text not null,
  scale text not null,
  release_year int not null,
  part_count int,
  model_number text,
  notes text,
  price_paid numeric,
  status text not null default 'backlog',
  acquired_date timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  custom_tags text[] not null default '{}'
);

create index if not exists collection_items_user_id_idx on public.collection_items(user_id);
create index if not exists collection_items_updated_at_idx on public.collection_items(updated_at desc);

alter table public.collection_items enable row level security;

create policy "Users read own collection"
  on public.collection_items for select
  using (auth.uid() = user_id);

create policy "Users insert own collection"
  on public.collection_items for insert
  with check (auth.uid() = user_id);

create policy "Users update own collection"
  on public.collection_items for update
  using (auth.uid() = user_id);

create policy "Users delete own collection"
  on public.collection_items for delete
  using (auth.uid() = user_id);
