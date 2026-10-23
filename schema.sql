-- Jalankan di Supabase > SQL Editor
create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  event_date date not null,
  location text not null,
  image_url text,
  is_visited boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.events enable row level security;

create policy "owner full access" on public.events
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
