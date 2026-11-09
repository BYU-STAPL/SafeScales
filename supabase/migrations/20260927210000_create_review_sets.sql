DO $$
DECLARE
  module_id_type text;
BEGIN
  SELECT format_type(attribute.atttypid, attribute.atttypmod)
  INTO module_id_type
  FROM pg_attribute AS attribute
  WHERE attribute.attrelid = 'public.modules'::regclass
    AND attribute.attname = 'id'
    AND NOT attribute.attisdropped;

  IF module_id_type IS NULL THEN
    RAISE EXCEPTION 'Could not determine public.modules.id type';
  END IF;

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS public.review_sets (
      module_id %s PRIMARY KEY REFERENCES public.modules(id) ON DELETE CASCADE,
      questions jsonb NOT NULL CHECK (
        jsonb_typeof(questions) = ''array''
        AND jsonb_array_length(questions) = 5
      )
    )',
    module_id_type
  );
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp.try_parse_review_questions(value text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN value::jsonb;
EXCEPTION
  WHEN invalid_text_representation THEN
    RETURN NULL;
END;
$$;

WITH module_pools AS (
  SELECT
    module.id,
    CASE
      WHEN jsonb_typeof(to_jsonb(module.revision_questions)) = 'string'
        THEN pg_temp.try_parse_review_questions(
          to_jsonb(module.revision_questions) #>> '{}'
        )
      ELSE to_jsonb(module.revision_questions)
    END AS review_data
  FROM public.modules AS module
),
question_pools AS (
  SELECT
    id,
    CASE
      WHEN jsonb_typeof(review_data) = 'array' THEN review_data
      WHEN jsonb_typeof(review_data -> 'questions') = 'array'
        THEN review_data -> 'questions'
      ELSE '[]'::jsonb
    END AS questions
  FROM module_pools
),
valid_questions AS (
  SELECT
    pool.id AS module_id,
    item.question,
    item.ordinality
  FROM question_pools AS pool
  CROSS JOIN LATERAL jsonb_array_elements(pool.questions)
    WITH ORDINALITY AS item(question, ordinality)
  WHERE jsonb_typeof(item.question) = 'object'
    AND btrim(COALESCE(item.question ->> 'question', '')) <> ''
    AND CASE
      WHEN jsonb_typeof(item.question -> 'choices') = 'array' THEN
        EXISTS (
          SELECT 1
          FROM jsonb_array_elements(item.question -> 'choices') AS choice(value)
          WHERE COALESCE(choice.value #>> '{}', choice.value::text) <> ''
        )
      ELSE false
    END
    AND CASE
      WHEN jsonb_typeof(item.question -> 'answer') = 'number'
        AND (item.question ->> 'answer') ~ '^(0|[1-9][0-9]*)$'
        THEN (item.question ->> 'answer')::numeric < (
          SELECT count(*)::numeric
          FROM jsonb_array_elements(item.question -> 'choices') AS choice(value)
          WHERE COALESCE(choice.value #>> '{}', choice.value::text) <> ''
        )
      WHEN jsonb_typeof(item.question -> 'answer') = 'string'
        AND (item.question ->> 'answer') ~ '^(0|[1-9][0-9]*)$'
        THEN (item.question ->> 'answer')::numeric < (
          SELECT count(*)::numeric
          FROM jsonb_array_elements(item.question -> 'choices') AS choice(value)
          WHERE COALESCE(choice.value #>> '{}', choice.value::text) <> ''
        )
      ELSE false
    END
),
ranked_questions AS (
  SELECT
    module_id,
    question,
    ordinality,
    row_number() OVER (
      PARTITION BY module_id
      ORDER BY ordinality
    ) AS question_number
  FROM valid_questions
),
fixed_sets AS (
  SELECT
    module_id,
    jsonb_agg(question ORDER BY ordinality) AS questions
  FROM ranked_questions
  WHERE question_number <= 5
  GROUP BY module_id
  HAVING count(*) = 5
)
INSERT INTO public.review_sets (module_id, questions)
SELECT module_id, questions
FROM fixed_sets
ON CONFLICT (module_id) DO NOTHING;

ALTER TABLE public.review_sets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS review_sets_read_all ON public.review_sets;
CREATE POLICY review_sets_read_all
  ON public.review_sets
  FOR SELECT
  TO anon, authenticated
  USING (true);
GRANT SELECT ON public.review_sets TO anon, authenticated;
