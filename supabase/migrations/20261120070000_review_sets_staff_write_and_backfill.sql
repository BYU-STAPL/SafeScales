-- Allow staff to write review_sets / modules, expand bank size, and backfill
-- from dashboard-authored modules.revision_questions.

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

REVOKE ALL ON FUNCTION public.current_user_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_staff() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff() TO authenticated;

-- modules: staff write (dashboard CreateClass saves here)
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

-- review_sets: staff write (synced from dashboard revision quiz)
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

-- Allow question banks of 5+ (app batches consecutive groups of five)
ALTER TABLE public.review_sets
  DROP CONSTRAINT IF EXISTS review_sets_questions_check;
ALTER TABLE public.review_sets
  DROP CONSTRAINT IF EXISTS review_sets_questions_bank_check;
ALTER TABLE public.review_sets
  ADD CONSTRAINT review_sets_questions_bank_check
  CHECK (
    jsonb_typeof(questions) = 'array'
    AND jsonb_array_length(questions) >= 5
  );

-- Backfill missing review_sets from modules.revision_questions when the pool
-- already has at least five questions.
WITH module_pools AS (
  SELECT
    module.id AS module_id,
    CASE
      WHEN module.revision_questions IS NULL THEN NULL
      WHEN jsonb_typeof(to_jsonb(module.revision_questions)) = 'string'
        THEN (to_jsonb(module.revision_questions) #>> '{}')::jsonb
      ELSE to_jsonb(module.revision_questions)
    END AS pool
  FROM public.modules AS module
),
normalized AS (
  SELECT
    module_id,
    CASE
      WHEN pool IS NULL THEN NULL
      WHEN jsonb_typeof(pool) = 'array' THEN pool
      WHEN jsonb_typeof(pool) = 'object' AND pool ? 'questions'
        THEN pool -> 'questions'
      ELSE NULL
    END AS questions
  FROM module_pools
)
INSERT INTO public.review_sets (module_id, questions)
SELECT module_id, questions
FROM normalized
WHERE questions IS NOT NULL
  AND jsonb_typeof(questions) = 'array'
  AND jsonb_array_length(questions) >= 5
ON CONFLICT (module_id) DO UPDATE
SET questions = EXCLUDED.questions;
