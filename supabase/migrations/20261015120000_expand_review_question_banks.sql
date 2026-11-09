ALTER TABLE public.review_sets
  DROP CONSTRAINT IF EXISTS review_sets_questions_check;

ALTER TABLE public.review_sets
  ADD CONSTRAINT review_sets_questions_bank_check
  CHECK (
    jsonb_typeof(questions) = 'array'
    AND jsonb_array_length(questions) >= 5
  );

CREATE INDEX IF NOT EXISTS activity_events_review_completion_idx
  ON public.activity_events (user_id, context_id)
  WHERE event_type = 'review_set_completed'
    AND context_type = 'review_set';

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
question_banks AS (
  SELECT
    module_id,
    jsonb_agg(question ORDER BY ordinality) AS questions
  FROM valid_questions
  GROUP BY module_id
  HAVING count(*) >= 5
)
UPDATE public.review_sets AS stored
SET questions = bank.questions
FROM question_banks AS bank
WHERE stored.module_id = bank.module_id
  AND jsonb_array_length(stored.questions) = 5;
