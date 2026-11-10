# Review question banks

Each lesson's `review_sets.questions` value is an ordered JSON array of
questions. Each question must have a non-empty `question`, a non-empty `choices`
array, and an `answer` containing the zero-based index of the correct choice.
An optional `explanation` is also supported. The review-set migration seeds
this array from `modules.revision_questions`, which may be either an array or
an object with a `questions` array.

A bank must contain at least five valid questions. Lesson review sets use
consecutive groups of five in the stored order. After the final group, the
sequence starts again at the beginning. If the bank does not divide evenly
into groups of five, its final group contains the remaining questions.

Progress is tracked separately for each user and lesson. Only completing a
lesson review advances that user's next group; leaving a review incomplete does
not. The random review option does not use this progression.
