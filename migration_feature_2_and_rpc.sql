-- ==============================================================================
-- EVENT-TIX MIGRATION SCRIPT: FEATURE 2 (TRANSAKSI EVENT) & ATOMIC RPC LEDGER
-- Jalankan skrip ini di Supabase Dashboard > SQL Editor
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PENYESUAIAN STRUKTUR TABEL savings_pocket_transactions
-- ------------------------------------------------------------------------------
ALTER TABLE public.savings_pocket_transactions
  ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS entry_source text NOT NULL DEFAULT 'manual' CHECK (entry_source IN ('manual', 'event')),
  ADD COLUMN IF NOT EXISTS idempotency_key text;

-- Indeks untuk performa dan keamanan idempotensi
CREATE UNIQUE INDEX IF NOT EXISTS idx_savings_tx_idempotency 
  ON public.savings_pocket_transactions(user_id, idempotency_key) 
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_savings_tx_event 
  ON public.savings_pocket_transactions(event_id);

CREATE INDEX IF NOT EXISTS idx_savings_tx_user_date 
  ON public.savings_pocket_transactions(user_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_events_eligible 
  ON public.events(user_id, is_favorite, is_visited);

-- Constraint agar current_amount tidak pernah minus
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_pocket_balance_non_negative'
  ) THEN
    ALTER TABLE public.savings_pockets
      ADD CONSTRAINT chk_pocket_balance_non_negative CHECK (current_amount >= 0);
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. ATOMIC RPC FUNCTION: create_event_transaction (Feature 2)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_event_transaction(
  p_event_id uuid,
  p_pocket_id uuid,
  p_amount numeric,
  p_transaction_date timestamptz,
  p_notes text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_event record;
  v_pocket record;
  v_new_tx record;
  v_existing_tx record;
BEGIN
  -- 1. Validasi Autentikasi Pengguna
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: pengguna belum login.';
  END IF;

  -- 2. Idempotency Check: cegah pemotongan saldo ganda
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_existing_tx
    FROM public.savings_pocket_transactions
    WHERE user_id = v_user_id AND idempotency_key = p_idempotency_key;

    IF FOUND THEN
      RETURN to_jsonb(v_existing_tx);
    END IF;
  END IF;

  -- 3. Validasi Nominal Pengeluaran
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Nominal transaksi harus lebih besar dari 0.';
  END IF;

  -- 4. Validasi Event: Harus milik pengguna, wishlist (is_favorite = true), dan sudah dikunjungi (is_visited = true)
  SELECT * INTO v_event
  FROM public.events
  WHERE id = p_event_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event tidak ditemukan atau bukan milik Anda.';
  END IF;

  IF NOT (v_event.is_favorite IS TRUE AND v_event.is_visited IS TRUE) THEN
    RAISE EXCEPTION 'Event belum memenuhi syarat (harus masuk Wishlist dan Sudah Dikunjungi).';
  END IF;

  -- 5. Validasi & Lock Row Pocket (mencegah race condition)
  SELECT * INTO v_pocket
  FROM public.savings_pockets
  WHERE id = p_pocket_id AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pocket / Kas tabungan tidak ditemukan atau bukan milik Anda.';
  END IF;

  -- 6. Validasi Saldo Cukup
  IF v_pocket.current_amount < p_amount THEN
    RAISE EXCEPTION 'Saldo Pocket "%" tidak mencukupi (Saldo: %, Dibutuhkan: %).',
      v_pocket.name, v_pocket.current_amount, p_amount;
  END IF;

  -- 7. Insert ke Ledger
  INSERT INTO public.savings_pocket_transactions (
    user_id,
    pocket_id,
    event_id,
    transaction_type,
    entry_source,
    amount,
    notes,
    transaction_date,
    idempotency_key
  ) VALUES (
    v_user_id,
    p_pocket_id,
    p_event_id,
    'withdraw',
    'event',
    p_amount,
    p_notes,
    COALESCE(p_transaction_date, now()),
    p_idempotency_key
  )
  RETURNING * INTO v_new_tx;

  -- 8. Kurangi Saldo Pocket secara Atomik
  UPDATE public.savings_pockets
  SET current_amount = current_amount - p_amount
  WHERE id = p_pocket_id;

  RETURN jsonb_build_object(
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
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. ATOMIC RPC FUNCTION: update_event_transaction (Feature 2)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_event_transaction(
  p_transaction_id uuid,
  p_new_event_id uuid,
  p_new_pocket_id uuid,
  p_new_amount numeric,
  p_new_transaction_date timestamptz,
  p_new_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_old_tx record;
  v_event record;
  v_old_pocket record;
  v_new_pocket record;
  v_diff numeric;
  v_updated_tx record;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: pengguna belum login.';
  END IF;

  IF p_new_amount IS NULL OR p_new_amount <= 0 THEN
    RAISE EXCEPTION 'Nominal baru harus lebih besar dari 0.';
  END IF;

  -- 1. Lock transaksi yang akan diubah
  SELECT * INTO v_old_tx
  FROM public.savings_pocket_transactions
  WHERE id = p_transaction_id AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaksi tidak ditemukan atau bukan milik Anda.';
  END IF;

  -- 2. Validasi Event baru
  SELECT * INTO v_event
  FROM public.events
  WHERE id = p_new_event_id AND user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Event baru tidak ditemukan atau bukan milik Anda.';
  END IF;

  IF NOT (v_event.is_favorite IS TRUE AND v_event.is_visited IS TRUE) THEN
    RAISE EXCEPTION 'Event baru belum memenuhi syarat (harus Wishlist dan Sudah Dikunjungi).';
  END IF;

  -- 3. Penyesuaian Saldo Atomik
  IF v_old_tx.pocket_id = p_new_pocket_id THEN
    -- Kasus Pocket Sama: hitung selisih
    SELECT * INTO v_old_pocket
    FROM public.savings_pockets
    WHERE id = p_new_pocket_id AND user_id = v_user_id
    FOR UPDATE;

    v_diff := p_new_amount - v_old_tx.amount;

    IF v_diff > 0 AND v_old_pocket.current_amount < v_diff THEN
      RAISE EXCEPTION 'Saldo Pocket "%" tidak mencukupi untuk kenaikan pengeluaran ini.', v_old_pocket.name;
    END IF;

    UPDATE public.savings_pockets
    SET current_amount = current_amount - v_diff
    WHERE id = p_new_pocket_id;
  ELSE
    -- Kasus Pocket Berbeda: kembalikan dana ke pocket lama, potong dari pocket baru
    SELECT * INTO v_old_pocket
    FROM public.savings_pockets
    WHERE id = v_old_tx.pocket_id AND user_id = v_user_id
    FOR UPDATE;

    SELECT * INTO v_new_pocket
    FROM public.savings_pockets
    WHERE id = p_new_pocket_id AND user_id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Pocket tujuan baru tidak ditemukan.';
    END IF;

    IF v_new_pocket.current_amount < p_new_amount THEN
      RAISE EXCEPTION 'Saldo pada Pocket baru "%" tidak mencukupi.', v_new_pocket.name;
    END IF;

    -- Kembalikan ke pocket lama
    UPDATE public.savings_pockets
    SET current_amount = current_amount + v_old_tx.amount
    WHERE id = v_old_tx.pocket_id;

    -- Potong dari pocket baru
    UPDATE public.savings_pockets
    SET current_amount = current_amount - p_new_amount
    WHERE id = p_new_pocket_id;
  END IF;

  -- 4. Update data transaksi
  UPDATE public.savings_pocket_transactions
  SET
    event_id = p_new_event_id,
    pocket_id = p_new_pocket_id,
    amount = p_new_amount,
    transaction_date = COALESCE(p_new_transaction_date, transaction_date),
    notes = p_new_notes
  WHERE id = p_transaction_id
  RETURNING * INTO v_updated_tx;

  RETURN to_jsonb(v_updated_tx);
END;
$$;

-- ------------------------------------------------------------------------------
-- 4. ATOMIC RPC FUNCTION: delete_event_transaction (Feature 2 & 3)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_event_transaction(
  p_transaction_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_tx record;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: pengguna belum login.';
  END IF;

  -- 1. Lock transaksi
  SELECT * INTO v_tx
  FROM public.savings_pocket_transactions
  WHERE id = p_transaction_id AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaksi tidak ditemukan atau bukan milik Anda.';
  END IF;

  -- 2. Kembalikan saldo ke Pocket hanya sekali (idempotent rollback)
  IF v_tx.transaction_type = 'withdraw' THEN
    UPDATE public.savings_pockets
    SET current_amount = current_amount + v_tx.amount
    WHERE id = v_tx.pocket_id AND user_id = v_user_id;
  ELSIF v_tx.transaction_type = 'deposit' THEN
    UPDATE public.savings_pockets
    SET current_amount = current_amount - v_tx.amount
    WHERE id = v_tx.pocket_id AND user_id = v_user_id;
  END IF;

  -- 3. Hapus transaksi
  DELETE FROM public.savings_pocket_transactions
  WHERE id = p_transaction_id;

  RETURN true;
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. ATOMIC RPC FUNCTION: create_manual_pocket_transaction (Feature 3)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_manual_pocket_transaction(
  p_pocket_id uuid,
  p_transaction_type text,
  p_amount numeric,
  p_transaction_date timestamptz,
  p_notes text DEFAULT NULL,
  p_idempotency_key text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_pocket record;
  v_new_tx record;
  v_existing_tx record;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Akses ditolak: pengguna belum login.';
  END IF;

  IF p_transaction_type NOT IN ('deposit', 'withdraw') THEN
    RAISE EXCEPTION 'Jenis transaksi tidak valid (harus deposit atau withdraw).';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Nominal transaksi harus lebih besar dari 0.';
  END IF;

  -- Idempotency check
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_existing_tx
    FROM public.savings_pocket_transactions
    WHERE user_id = v_user_id AND idempotency_key = p_idempotency_key;

    IF FOUND THEN
      RETURN to_jsonb(v_existing_tx);
    END IF;
  END IF;

  -- Lock row pocket
  SELECT * INTO v_pocket
  FROM public.savings_pockets
  WHERE id = p_pocket_id AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pocket tabungan tidak ditemukan atau bukan milik Anda.';
  END IF;

  IF p_transaction_type = 'withdraw' AND v_pocket.current_amount < p_amount THEN
    RAISE EXCEPTION 'Saldo pada Pocket "%" tidak mencukupi (Saldo: %, Dibutuhkan: %).',
      v_pocket.name, v_pocket.current_amount, p_amount;
  END IF;

  -- Insert ledger
  INSERT INTO public.savings_pocket_transactions (
    user_id,
    pocket_id,
    event_id,
    transaction_type,
    entry_source,
    amount,
    notes,
    transaction_date,
    idempotency_key
  ) VALUES (
    v_user_id,
    p_pocket_id,
    NULL,
    p_transaction_type,
    'manual',
    p_amount,
    p_notes,
    COALESCE(p_transaction_date, now()),
    p_idempotency_key
  ) RETURNING * INTO v_new_tx;

  -- Update saldo Pocket
  IF p_transaction_type = 'deposit' THEN
    UPDATE public.savings_pockets
    SET current_amount = current_amount + p_amount
    WHERE id = p_pocket_id;
  ELSE
    UPDATE public.savings_pockets
    SET current_amount = current_amount - p_amount
    WHERE id = p_pocket_id;
  END IF;

  RETURN to_jsonb(v_new_tx);
END;
$$;
