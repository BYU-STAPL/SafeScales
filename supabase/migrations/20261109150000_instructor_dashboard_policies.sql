-- Instructor / researcher dashboard policies
-- Extends student-only RLS so authenticated staff can manage classes/modules
-- and view students in classes they instruct. Auth user creation still uses
-- service role (dashboard-admin Edge Function).

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM public."Users"
  WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(public.current_user_role(), '') IN ('instructor', 'researcher', 'admin');
$$;

CREATE OR REPLACE FUNCTION public.instructs_class(p_class_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.classes c
    WHERE c.id = p_class_id
      AND c.instructor_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION public.current_user_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_staff() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.instructs_class(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.instructs_class(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Auth trigger: allow staff roles from signup metadata (dashboard only)
-- Student app / class-code-auth should omit role or pass student.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  meta_role text := lower(COALESCE(NEW.raw_user_meta_data->>'role', 'student'));
  profile_role text;
BEGIN
  IF meta_role IN ('instructor', 'researcher', 'admin') THEN
    profile_role := meta_role;
  ELSE
    profile_role := 'student';
  END IF;

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
    profile_role,
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

REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_auth_user() FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO postgres, service_role, supabase_auth_admin;

-- ---------------------------------------------------------------------------
-- Users: staff can read roster members of classes they instruct
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS users_select_own ON public."Users";
CREATE POLICY users_select_own
  ON public."Users"
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR (
      public.is_staff()
      AND EXISTS (
        SELECT 1
        FROM public.classes c
        WHERE c.instructor_id = auth.uid()
          AND c.id = ANY (COALESCE(joined_classes, ARRAY[]::uuid[]))
      )
    )
  );

-- Staff may update roster fields for students in their classes (role/Email/id
-- remain blocked by prevent_users_privilege_escalation trigger).
DROP POLICY IF EXISTS users_update_own ON public."Users";
CREATE POLICY users_update_own
  ON public."Users"
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = id
    OR (
      public.is_staff()
      AND EXISTS (
        SELECT 1
        FROM public.classes c
        WHERE c.instructor_id = auth.uid()
          AND c.id = ANY (COALESCE(joined_classes, ARRAY[]::uuid[]))
      )
    )
  )
  WITH CHECK (
    auth.uid() = id
    OR public.is_staff()
  );

-- ---------------------------------------------------------------------------
-- classes: staff CRUD for own classes; researchers/admins can manage all
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS classes_select_authenticated ON public.classes;
CREATE POLICY classes_select_authenticated
  ON public.classes
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS classes_insert_staff ON public.classes;
CREATE POLICY classes_insert_staff
  ON public.classes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_staff()
    AND instructor_id = auth.uid()
  );

DROP POLICY IF EXISTS classes_update_staff ON public.classes;
CREATE POLICY classes_update_staff
  ON public.classes
  FOR UPDATE
  TO authenticated
  USING (
    public.is_staff()
    AND (
      instructor_id = auth.uid()
      OR public.current_user_role() IN ('researcher', 'admin')
    )
  )
  WITH CHECK (
    public.is_staff()
    AND (
      instructor_id = auth.uid()
      OR public.current_user_role() IN ('researcher', 'admin')
    )
  );

DROP POLICY IF EXISTS classes_delete_staff ON public.classes;
CREATE POLICY classes_delete_staff
  ON public.classes
  FOR DELETE
  TO authenticated
  USING (
    public.is_staff()
    AND (
      instructor_id = auth.uid()
      OR public.current_user_role() IN ('researcher', 'admin')
    )
  );

GRANT INSERT, UPDATE, DELETE ON TABLE public.classes TO authenticated;

-- ---------------------------------------------------------------------------
-- modules / review_sets / asset tables: staff write, everyone authenticated read
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS modules_insert_staff ON public.modules;
CREATE POLICY modules_insert_staff
  ON public.modules FOR INSERT TO authenticated
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS modules_update_staff ON public.modules;
CREATE POLICY modules_update_staff
  ON public.modules FOR UPDATE TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS modules_delete_staff ON public.modules;
CREATE POLICY modules_delete_staff
  ON public.modules FOR DELETE TO authenticated
  USING (public.is_staff());

GRANT INSERT, UPDATE, DELETE ON TABLE public.modules TO authenticated;

DROP POLICY IF EXISTS review_sets_insert_staff ON public.review_sets;
CREATE POLICY review_sets_insert_staff
  ON public.review_sets FOR INSERT TO authenticated
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS review_sets_update_staff ON public.review_sets;
CREATE POLICY review_sets_update_staff
  ON public.review_sets FOR UPDATE TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS review_sets_delete_staff ON public.review_sets;
CREATE POLICY review_sets_delete_staff
  ON public.review_sets FOR DELETE TO authenticated
  USING (public.is_staff());

GRANT INSERT, UPDATE, DELETE ON TABLE public.review_sets TO authenticated;

DROP POLICY IF EXISTS dragons_write_staff ON public.dragons;
CREATE POLICY dragons_write_staff
  ON public.dragons FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS accessories_write_staff ON public.accessories;
CREATE POLICY accessories_write_staff
  ON public.accessories FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS environments_write_staff ON public.environments;
CREATE POLICY environments_write_staff
  ON public.environments FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS field_sites_write_staff ON public."fieldSites";
CREATE POLICY field_sites_write_staff
  ON public."fieldSites" FOR ALL TO authenticated
  USING (public.is_staff())
  WITH CHECK (public.is_staff());

GRANT INSERT, UPDATE, DELETE ON TABLE public.dragons TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.accessories TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.environments TO authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public."fieldSites" TO authenticated;

-- quiz_attempts: staff can read attempts for students in their classes
DROP POLICY IF EXISTS quiz_attempts_select_staff_roster ON public.quiz_attempts;
CREATE POLICY quiz_attempts_select_staff_roster
  ON public.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR (
      public.is_staff()
      AND EXISTS (
        SELECT 1
        FROM public."Users" u
        JOIN public.classes c ON c.id = ANY (COALESCE(u.joined_classes, ARRAY[]::uuid[]))
        WHERE u.id = quiz_attempts.user_id
          AND c.instructor_id = auth.uid()
      )
    )
  );
