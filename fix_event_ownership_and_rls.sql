-- ==============================================================================
-- FIX KEPEMILIKAN EVENT & IZIN RLS (Supabase SQL Editor)
-- Jalankan skrip ini di Supabase Dashboard > SQL Editor > Run
-- ==============================================================================

-- 1. Pindahkan kepemilikan SEMUA event yang ada ke akun geatasya@gmail.com
UPDATE public.events
SET user_id = (SELECT id FROM auth.users WHERE email = 'geatasya@gmail.com' LIMIT 1);

-- 2. Hapus semua policy lama pada tabel events agar bersih dari konflik
DROP POLICY IF EXISTS "owner full access on events" ON public.events;
DROP POLICY IF EXISTS "owner full access" ON public.events;
DROP POLICY IF EXISTS "allow read all events" ON public.events;
DROP POLICY IF EXISTS "allow update events" ON public.events;
DROP POLICY IF EXISTS "allow insert events" ON public.events;
DROP POLICY IF EXISTS "allow delete events" ON public.events;

-- 3. Pasang policy baru yang mengizinkan authenticated user membaca dan mengupdate data
CREATE POLICY "allow read all events" ON public.events
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow update events" ON public.events
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow insert events" ON public.events
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "allow delete events" ON public.events
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR user_id IS NULL);

-- 4. Verifikasi hasil update: pastikan user_id sekarang terisi
SELECT id, name, user_id, is_visited, is_favorite FROM public.events;
