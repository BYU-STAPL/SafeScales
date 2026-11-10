# Data collection and export

SafeScales writes append-only interaction history to Supabase's
`public.activity_events` table. Existing user progress and game state remain in
their current tables; this event table records dated changes and activity
details that would otherwise be lost when state is updated.

Each row includes:

- `user_id`: authenticated participant UUID.
- `session_id`: a client-generated identifier shared by events in one app
  process.
- `event_type`: the interaction name, such as `quiz_question_answered`,
  `reading_page_duration`, or `item_unlocked`.
- `context_type` and `context_id`: the related lesson, quiz, review set, dragon,
  item, habitat, or navigation tab where applicable.
- `occurred_at`: client event time in UTC; `created_at` is the database receipt
  time.
- `details`: event-specific structured JSON. Durations are milliseconds,
  question/page indices are zero-based, and responses are selected option
  indices. `active_duration_ms` and page/question duration values exclude time
  while SafeScales is backgrounded; `duration_ms` on completed quiz/review
  summaries is elapsed wall-clock time.

The table includes quiz attempt start/completion and final per-question answers,
correctness and time; review set selection, question responses/retries,
completion and question time; repeated reading sessions, page visits and total
duration; and dated game events for unlocks, dragon names/phases, habitat and
decoration changes, game-session duration, and resets. Decoration moves,
resizes, and layer changes are timestamped when the gesture completes rather
than on every drag update. Accessory and habitat unlocks are recorded after a
successful purchase. Lesson page visits and active durations, top-level tab
selections, and foreground tab durations are also recorded. Lesson time pauses
while a reading, quiz, or review screen is open and while SafeScales is
backgrounded. App background/resume events indicate only SafeScales lifecycle
transitions; they do not identify another app.

Quiz and review response events retain the selected response for each
question/attempt, while quiz completion events retain the attempt score and
timing. Reading events distinguish repeated sessions, page visits, and page
durations. Game events record the new state for name/phase changes and include
the relevant item, habitat, or decoration identifiers. This is event history:
existing tables continue to hold the latest progress and game state.

## Export

An authorized project administrator can open **Supabase Dashboard → Table
Editor → `activity_events`** and use the table export/download action to save a
CSV. The `details` JSON column is retained as a CSV field. Filter by participant,
event type, session, or date before exporting when a smaller extract is needed.
The app's authenticated Data API policies intentionally expose only each
participant's own rows; broad research exports should be performed with an
authorized administrator account in the dashboard, not by weakening those
policies.

## Access controls

The migration enables row-level security, allows authenticated participants to
insert and read only their own events, and grants no participant update/delete
access. Supabase dashboard administration remains the authorized export path.
Before collecting study data, confirm project dashboard membership is limited
to approved personnel and that the study/privacy notice describes event and
app foreground/background collection.
