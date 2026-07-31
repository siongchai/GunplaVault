-- Additive: store catalog box art URL on collection items (optional)
alter table public.collection_items
  add column if not exists box_art_url text;
