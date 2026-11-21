-- ==============================================================================
-- EVENT-TIX SUPABASE DATABASE SCHEMA
-- Jalankan skrip ini di Supabase Dashboard > SQL Editor
-- Mencakup: Fitur 1 (Jadwal Konser) & Fitur 3 (Kantong Tabungan Konser)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TABEL EVENTS (Fitur 1: Jadwal Konser / Concert Radar)
-- ------------------------------------------------------------------------------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  event_date date not null,
  end_date date,
  start_time text,
  end_time text,
  door_time text,
  location text not null,
  address text,
  event_type text,
  category text,
  description text,
  lineup text,
  ticket_url text,
  ticket_tier text,
  price_from bigint,
  saved_amount bigint,
  notes text,
  checklist text,
  image_url text,
  is_visited boolean not null default false,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.events enable row level security;

create policy "owner full access on events" on public.events
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 2. SUPABASE STORAGE (Bucket: posters untuk Poster Konser)
-- ------------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('posters', 'posters', true)
on conflict (id) do nothing;

create policy "Public Access to Posters"
  on storage.objects for select
  using (bucket_id = 'posters');

create policy "Authenticated Users can upload posters"
  on storage.objects for insert
  with check (bucket_id = 'posters' and auth.role() = 'authenticated');

create policy "Users can update own posters"
  on storage.objects for update
  using (bucket_id = 'posters' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can delete own posters"
  on storage.objects for delete
  using (bucket_id = 'posters' and auth.uid()::text = (storage.foldername(name))[1]);

-- ------------------------------------------------------------------------------
-- 3. TABEL SAVINGS POCKETS (Fitur 3: Kantong Tabungan Tiket Konser)
-- ------------------------------------------------------------------------------
create table if not exists public.savings_pockets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  target_amount numeric not null default 0,
  current_amount numeric not null default 0,
  created_at timestamptz not null default now()
);

alter table public.savings_pockets enable row level security;

create policy "owner full access on savings_pockets" on public.savings_pockets
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 4. TABEL TRANSAKSI TABUNGAN (Fitur 3: Deposit & Withdraw Tabungan)
-- ------------------------------------------------------------------------------
create table if not exists public.savings_pocket_transactions (
  id uuid primary key default gen_random_uuid(),
  pocket_id uuid not null references public.savings_pockets(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  transaction_type text not null check (transaction_type in ('deposit', 'withdraw')),
  amount numeric not null default 0,
  notes text,
  transaction_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.savings_pocket_transactions enable row level security;

create policy "owner full access on savings_pocket_transactions" on public.savings_pocket_transactions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
