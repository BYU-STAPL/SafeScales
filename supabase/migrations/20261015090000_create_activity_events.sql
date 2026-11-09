CREATE TABLE IF NOT EXISTS public.activity_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id text NOT NULL CHECK (length(session_id) > 0),
  event_type text NOT NULL CHECK (length(event_type) > 0),
  context_type text,
  context_id text,
  occurred_at timestamptz NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (
    jsonb_typeof(details) = 'object'
  ),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS activity_events_user_occurred_at_idx
  ON public.activity_events (user_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_type_occurred_at_idx
  ON public.activity_events (event_type, occurred_at DESC);

CREATE INDEX IF NOT EXISTS activity_events_session_occurred_at_idx
  ON public.activity_events (session_id, occurred_at);

ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS activity_events_select_own
  ON public.activity_events;
CREATE POLICY activity_events_select_own
  ON public.activity_events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS activity_events_insert_own
  ON public.activity_events;
CREATE POLICY activity_events_insert_own
  ON public.activity_events
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

REVOKE UPDATE, DELETE ON public.activity_events FROM anon, authenticated;
GRANT SELECT, INSERT ON public.activity_events TO authenticated;
