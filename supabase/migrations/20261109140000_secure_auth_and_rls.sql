-- Secure Auth + RLS
-- 1) Align mismatched Users.id with auth.users for shared emails
-- 2) Drop plaintext password column
-- 3) Auto-create profile rows on auth.users insert
-- 4) Enable RLS + least-privilege grants on public tables

-- ---------------------------------------------------------------------------
-- Align Users.id with auth.users when emails match but IDs differ
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  ALTER TABLE public.classes DROP CONSTRAINT IF EXISTS classes_instructor_id_fkey;

  FOR r IN
    SELECT u.id AS users_id, a.id AS auth_id
    FROM public."Users" u
    JOIN auth.users a ON lower(a.email) = lower(u."Email")
    WHERE u.id <> a.id
      AND NOT EXISTS (SELECT 1 FROM public."Users" u2 WHERE u2.id = a.id)
  LOOP
    UPDATE public.quiz_attempts
    SET user_id = r.auth_id
    WHERE user_id = r.users_id;

    UPDATE public.classes
    SET instructor_id = r.auth_id
    WHERE instructor_id = r.users_id;

    UPDATE public."Users"
    SET id = r.auth_id
    WHERE id = r.users_id;
  END LOOP;

  ALTER TABLE public.classes
    ADD CONSTRAINT classes_instructor_id_fkey
    FOREIGN KEY (instructor_id) REFERENCES public."Users"(id);
END $$;

-- ---------------------------------------------------------------------------
-- Remove plaintext passwords (Auth stores bcrypt hashes in auth.users)
-- ---------------------------------------------------------------------------
ALTER TABLE public."Users" DROP COLUMN IF EXISTS password;

-- ---------------------------------------------------------------------------
-- Prevent clients from changing identity / privilege fields
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_users_privilege_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'Users.id cannot be changed';
  END IF;
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Users.role cannot be changed by clients';
  END IF;
  IF NEW."Email" IS DISTINCT FROM OLD."Email" THEN
    RAISE EXCEPTION 'Users.Email cannot be changed by clients';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_users_privilege_escalation ON public."Users";
CREATE TRIGGER trg_prevent_users_privilege_escalation
  BEFORE UPDATE ON public."Users"
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_users_privilege_escalation();

-- ---------------------------------------------------------------------------
-- Create profile when an Auth user is created (email signup / class-code)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public."Users" (
    id,
    "Email",
    "Username",
    role,
    settings,
    joined_classes,
    dragons,
    acquired_accessories,
    acquired_environments,
    reading_progress
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'username', ''),
      split_part(COALESCE(NEW.email, NEW.id::text), '@', 1)
    ),
    'student',
    '{"fontSize": 1.0, "isDarkMode": false}'::jsonb,
    ARRAY[]::uuid[],
    '{}'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    '{}'::jsonb
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public."Users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dragons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.environments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."fieldSites" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_sets ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Users policies: own row only
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS users_select_own ON public."Users";
CREATE POLICY users_select_own
  ON public."Users"
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS users_update_own ON public."Users";
CREATE POLICY users_update_own
  ON public."Users"
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- quiz_attempts: own rows
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS quiz_attempts_select_own ON public.quiz_attempts;
CREATE POLICY quiz_attempts_select_own
  ON public.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS quiz_attempts_insert_own ON public.quiz_attempts;
CREATE POLICY quiz_attempts_insert_own
  ON public.quiz_attempts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS quiz_attempts_update_own ON public.quiz_attempts;
CREATE POLICY quiz_attempts_update_own
  ON public.quiz_attempts
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Content tables: authenticated read-only
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS classes_select_authenticated ON public.classes;
CREATE POLICY classes_select_authenticated
  ON public.classes
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS modules_select_authenticated ON public.modules;
CREATE POLICY modules_select_authenticated
  ON public.modules
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS dragons_select_authenticated ON public.dragons;
CREATE POLICY dragons_select_authenticated
  ON public.dragons
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS accessories_select_authenticated ON public.accessories;
CREATE POLICY accessories_select_authenticated
  ON public.accessories
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS environments_select_authenticated ON public.environments;
CREATE POLICY environments_select_authenticated
  ON public.environments
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS field_sites_select_authenticated ON public."fieldSites";
CREATE POLICY field_sites_select_authenticated
  ON public."fieldSites"
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS review_sets_read_all ON public.review_sets;
DROP POLICY IF EXISTS review_sets_select_authenticated ON public.review_sets;
CREATE POLICY review_sets_select_authenticated
  ON public.review_sets
  FOR SELECT
  TO authenticated
  USING (true);

-- ---------------------------------------------------------------------------
-- Least-privilege grants (RLS still applies)
-- ---------------------------------------------------------------------------
REVOKE ALL ON TABLE public."Users" FROM anon, authenticated;
GRANT SELECT, UPDATE ON TABLE public."Users" TO authenticated;

REVOKE ALL ON TABLE public.quiz_attempts FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.quiz_attempts TO authenticated;

REVOKE ALL ON TABLE public.classes FROM anon, authenticated;
REVOKE ALL ON TABLE public.modules FROM anon, authenticated;
REVOKE ALL ON TABLE public.dragons FROM anon, authenticated;
REVOKE ALL ON TABLE public.accessories FROM anon, authenticated;
REVOKE ALL ON TABLE public.environments FROM anon, authenticated;
REVOKE ALL ON TABLE public."fieldSites" FROM anon, authenticated;
REVOKE ALL ON TABLE public.review_sets FROM anon, authenticated;

GRANT SELECT ON TABLE public.classes TO authenticated;
GRANT SELECT ON TABLE public.modules TO authenticated;
GRANT SELECT ON TABLE public.dragons TO authenticated;
GRANT SELECT ON TABLE public.accessories TO authenticated;
GRANT SELECT ON TABLE public.environments TO authenticated;
GRANT SELECT ON TABLE public."fieldSites" TO authenticated;
GRANT SELECT ON TABLE public.review_sets TO authenticated;

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO postgres, service_role, supabase_auth_admin;

REVOKE ALL ON FUNCTION public.prevent_users_privilege_escalation() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prevent_users_privilege_escalation() FROM anon, authenticated;
