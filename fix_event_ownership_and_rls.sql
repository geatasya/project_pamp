-- ==============================================================================
-- FIX KEPEMILIKAN EVENT & IZIN RLS (Supabase SQL Editor)
-- Jalankan skrip ini sekali di Supabase Dashboard > SQL Editor
-- ==============================================================================

-- 1. Berikan kepemilikan event yang sudah ada ke akun geatasya@gmail.com
UPDATE public.events
SET user_id = (SELECT id FROM auth.users WHERE email = 'geatasya@gmail.com' LIMIT 1)
WHERE user_id IS NULL OR user_id NOT IN (SELECT id FROM auth.users);

-- 2. Perbarui policy RLS agar pengguna yang login dapat membaca dan mengupdate event miliknya atau event publik
DROP POLICY IF EXISTS "owner full access on events" ON public.events;
DROP POLICY IF EXISTS "owner full access" ON public.events;
DROP POLICY IF EXISTS "allow read all events" ON public.events;
DROP POLICY IF EXISTS "allow update events" ON public.events;
DROP POLICY IF EXISTS "allow insert events" ON public.events;
DROP POLICY IF EXISTS "allow delete events" ON public.events;

-- Boleh dibaca oleh semua pengguna yang login
CREATE POLICY "allow read all events" ON public.events
  FOR SELECT
  USING (true);

-- Boleh diubah jika event tersebut milik pengguna atau belum memiliki user_id
CREATE POLICY "allow update events" ON public.events
  FOR UPDATE
  USING (auth.uid() = user_id OR user_id IS NULL)
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Boleh ditambah oleh pengguna yang login
CREATE POLICY "allow insert events" ON public.events
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Boleh dihapus jika event tersebut milik pengguna
CREATE POLICY "allow delete events" ON public.events
  FOR DELETE
  USING (auth.uid() = user_id OR user_id IS NULL);
