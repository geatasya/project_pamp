-- ==============================================================================
-- EVENT-TIX COMPLETE SUPABASE DATABASE SCHEMA
-- Jalankan skrip ini di Supabase Dashboard > SQL Editor
-- Mencakup: Fitur 1 (Jadwal Konser), Fitur 2 (Transaksi Event), & Fitur 3 (Tabungan)
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

create index if not exists idx_events_eligible on public.events(user_id, is_favorite, is_visited);

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

-- Constraint saldo tidak boleh minus
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'chk_pocket_balance_non_negative'
  ) then
    alter table public.savings_pockets
      add constraint chk_pocket_balance_non_negative check (current_amount >= 0);
  end if;
end $$;

-- ------------------------------------------------------------------------------
-- 4. TABEL TRANSAKSI KEUANGAN / LEDGER BERSAMA (Fitur 2 & Fitur 3)
-- ------------------------------------------------------------------------------
create table if not exists public.savings_pocket_transactions (
  id uuid primary key default gen_random_uuid(),
  pocket_id uuid not null references public.savings_pockets(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  event_id uuid references public.events(id) on delete set null,
  transaction_type text not null check (transaction_type in ('deposit', 'withdraw')),
  entry_source text not null default 'manual' check (entry_source in ('manual', 'event')),
  amount numeric not null default 0,
  notes text,
  transaction_date timestamptz not null default now(),
  idempotency_key text,
  created_at timestamptz not null default now()
);

alter table public.savings_pocket_transactions enable row level security;

create policy "owner full access on savings_pocket_transactions" on public.savings_pocket_transactions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create unique index if not exists idx_savings_tx_idempotency 
  on public.savings_pocket_transactions(user_id, idempotency_key) 
  where idempotency_key is not null;

create index if not exists idx_savings_tx_event 
  on public.savings_pocket_transactions(event_id);

create index if not exists idx_savings_tx_user_date 
  on public.savings_pocket_transactions(user_id, transaction_date desc);

-- ------------------------------------------------------------------------------
-- 5. ATOMIC RPC FUNCTIONS (Mencegah Race Condition & Inkonsistensi Saldo)
-- ------------------------------------------------------------------------------

-- A. Create Event Transaction (Feature 2)
create or replace function public.create_event_transaction(
  p_event_id uuid,
  p_pocket_id uuid,
  p_amount numeric,
  p_transaction_date timestamptz,
  p_notes text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_event record;
  v_pocket record;
  v_new_tx record;
  v_existing_tx record;
begin
  if v_user_id is null then
    raise exception 'Akses ditolak: pengguna belum login.';
  end if;

  if p_idempotency_key is not null then
    select * into v_existing_tx
    from public.savings_pocket_transactions
    where user_id = v_user_id and idempotency_key = p_idempotency_key;

    if found then
      return to_jsonb(v_existing_tx);
    end if;
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal transaksi harus lebih besar dari 0.';
  end if;

  select * into v_event
  from public.events
  where id = p_event_id and user_id = v_user_id;

  if not found then
    raise exception 'Event tidak ditemukan atau bukan milik Anda.';
  end if;

  if not (v_event.is_favorite is true and v_event.is_visited is true) then
    raise exception 'Event belum memenuhi syarat (harus masuk Wishlist dan Sudah Dikunjungi).';
  end if;

  select * into v_pocket
  from public.savings_pockets
  where id = p_pocket_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Pocket tabungan tidak ditemukan atau bukan milik Anda.';
  end if;

  if v_pocket.current_amount < p_amount then
    raise exception 'Saldo Pocket "%" tidak mencukupi (Saldo: %, Dibutuhkan: %).',
      v_pocket.name, v_pocket.current_amount, p_amount;
  end if;

  insert into public.savings_pocket_transactions (
    user_id,
    pocket_id,
    event_id,
    transaction_type,
    entry_source,
    amount,
    notes,
    transaction_date,
    idempotency_key
  ) values (
    v_user_id,
    p_pocket_id,
    p_event_id,
    'withdraw',
    'event',
    p_amount,
    p_notes,
    coalesce(p_transaction_date, now()),
    p_idempotency_key
  )
  returning * into v_new_tx;

  update public.savings_pockets
  set current_amount = current_amount - p_amount
  where id = p_pocket_id;

  return jsonb_build_object(
    'id', v_new_tx.id,
    'user_id', v_new_tx.user_id,
    'pocket_id', v_new_tx.pocket_id,
    'event_id', v_new_tx.event_id,
    'transaction_type', v_new_tx.transaction_type,
    'entry_source', v_new_tx.entry_source,
    'amount', v_new_tx.amount,
    'notes', v_new_tx.notes,
    'transaction_date', v_new_tx.transaction_date,
    'created_at', v_new_tx.created_at
  );
end;
$$;

-- B. Update Event Transaction (Feature 2)
create or replace function public.update_event_transaction(
  p_transaction_id uuid,
  p_new_event_id uuid,
  p_new_pocket_id uuid,
  p_new_amount numeric,
  p_new_transaction_date timestamptz,
  p_new_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_old_tx record;
  v_event record;
  v_old_pocket record;
  v_new_pocket record;
  v_diff numeric;
  v_updated_tx record;
begin
  if v_user_id is null then
    raise exception 'Akses ditolak: pengguna belum login.';
  end if;

  if p_new_amount is null or p_new_amount <= 0 then
    raise exception 'Nominal baru harus lebih besar dari 0.';
  end if;

  select * into v_old_tx
  from public.savings_pocket_transactions
  where id = p_transaction_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Transaksi tidak ditemukan atau bukan milik Anda.';
  end if;

  select * into v_event
  from public.events
  where id = p_new_event_id and user_id = v_user_id;

  if not found then
    raise exception 'Event baru tidak ditemukan atau bukan milik Anda.';
  end if;

  if not (v_event.is_favorite is true and v_event.is_visited is true) then
    raise exception 'Event baru belum memenuhi syarat (harus Wishlist dan Sudah Dikunjungi).';
  end if;

  if v_old_tx.pocket_id = p_new_pocket_id then
    select * into v_old_pocket
    from public.savings_pockets
    where id = p_new_pocket_id and user_id = v_user_id
    for update;

    v_diff := p_new_amount - v_old_tx.amount;

    if v_diff > 0 and v_old_pocket.current_amount < v_diff then
      raise exception 'Saldo Pocket "%" tidak mencukupi untuk kenaikan pengeluaran ini.', v_old_pocket.name;
    end if;

    update public.savings_pockets
    set current_amount = current_amount - v_diff
    where id = p_new_pocket_id;
  else
    select * into v_old_pocket
    from public.savings_pockets
    where id = v_old_tx.pocket_id and user_id = v_user_id
    for update;

    select * into v_new_pocket
    from public.savings_pockets
    where id = p_new_pocket_id and user_id = v_user_id
    for update;

    if not found then
      raise exception 'Pocket tujuan baru tidak ditemukan.';
    end if;

    if v_new_pocket.current_amount < p_new_amount then
      raise exception 'Saldo pada Pocket baru "%" tidak mencukupi.', v_new_pocket.name;
    end if;

    update public.savings_pockets
    set current_amount = current_amount + v_old_tx.amount
    where id = v_old_tx.pocket_id;

    update public.savings_pockets
    set current_amount = current_amount - p_new_amount
    where id = p_new_pocket_id;
  end if;

  update public.savings_pocket_transactions
  set
    event_id = p_new_event_id,
    pocket_id = p_new_pocket_id,
    amount = p_new_amount,
    transaction_date = coalesce(p_new_transaction_date, transaction_date),
    notes = p_new_notes
  where id = p_transaction_id
  returning * into v_updated_tx;

  return to_jsonb(v_updated_tx);
end;
$$;

-- C. Delete Event Transaction (Feature 2 & 3)
create or replace function public.delete_event_transaction(
  p_transaction_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tx record;
begin
  if v_user_id is null then
    raise exception 'Akses ditolak: pengguna belum login.';
  end if;

  select * into v_tx
  from public.savings_pocket_transactions
  where id = p_transaction_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Transaksi tidak ditemukan atau bukan milik Anda.';
  end if;

  if v_tx.transaction_type = 'withdraw' then
    update public.savings_pockets
    set current_amount = current_amount + v_tx.amount
    where id = v_tx.pocket_id and user_id = v_user_id;
  elsif v_tx.transaction_type = 'deposit' then
    update public.savings_pockets
    set current_amount = current_amount - v_tx.amount
    where id = v_tx.pocket_id and user_id = v_user_id;
  end if;

  delete from public.savings_pocket_transactions
  where id = p_transaction_id;

  return true;
end;
$$;

-- D. Create Manual Pocket Transaction (Feature 3)
create or replace function public.create_manual_pocket_transaction(
  p_pocket_id uuid,
  p_transaction_type text,
  p_amount numeric,
  p_transaction_date timestamptz,
  p_notes text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_pocket record;
  v_new_tx record;
  v_existing_tx record;
begin
  if v_user_id is null then
    raise exception 'Akses ditolak: pengguna belum login.';
  end if;

  if p_transaction_type not in ('deposit', 'withdraw') then
    raise exception 'Jenis transaksi tidak valid (harus deposit atau withdraw).';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal transaksi harus lebih besar dari 0.';
  end if;

  if p_idempotency_key is not null then
    select * into v_existing_tx
    from public.savings_pocket_transactions
    where user_id = v_user_id and idempotency_key = p_idempotency_key;

    if found then
      return to_jsonb(v_existing_tx);
    end if;
  end if;

  select * into v_pocket
  from public.savings_pockets
  where id = p_pocket_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'Pocket tabungan tidak ditemukan atau bukan milik Anda.';
  end if;

  if p_transaction_type = 'withdraw' and v_pocket.current_amount < p_amount then
    raise exception 'Saldo pada Pocket "%" tidak mencukupi (Saldo: %, Dibutuhkan: %).',
      v_pocket.name, v_pocket.current_amount, p_amount;
  end if;

  insert into public.savings_pocket_transactions (
    user_id,
    pocket_id,
    event_id,
    transaction_type,
    entry_source,
    amount,
    notes,
    transaction_date,
    idempotency_key
  ) values (
    v_user_id,
    p_pocket_id,
    null,
    p_transaction_type,
    'manual',
    p_amount,
    p_notes,
    coalesce(p_transaction_date, now()),
    p_idempotency_key
  ) returning * into v_new_tx;

  if p_transaction_type = 'deposit' then
    update public.savings_pockets
    set current_amount = current_amount + p_amount
    where id = p_pocket_id;
  else
    update public.savings_pockets
    set current_amount = current_amount - p_amount
    where id = p_pocket_id;
  end if;

  return to_jsonb(v_new_tx);
end;
$$;
