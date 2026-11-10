# Reading content format

Reading content is stored as an ordered list in `revision.slides`. Existing
entries with `headline` and `content` remain valid. A checkpoint can be
interleaved with those entries by setting `type` to `checkpoint` and supplying
the question, choices, correct choice index, and optional explanation:

```json
{
  "revision": {
    "slides": [
      {
        "headline": "Facebook Norms",
        "content": "It is common to create your own content or share others' posts."
      },
      {
        "type": "checkpoint",
        "headline": "Checkpoint Question",
        "question": "Can you create your own posts on Facebook?",
        "choices": ["Yes", "No"],
        "answer": 0,
        "explanation": "You can create your own posts on Facebook."
      }
    ]
  }
}
```

The `answer` value is a zero-based index into `choices`, matching the existing
quiz question format. The `headline` is optional for checkpoints and defaults
to `Checkpoint Question`. Learners can retry an incorrect answer; the reader
does not allow forward navigation past a checkpoint until it is answered
correctly. Backward navigation remains available.
