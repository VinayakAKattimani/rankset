# RankSet scoring function (mode A)

`submitAttempt` validates the answers, reads the hidden answer keys with the Admin SDK, computes the score, saves the
attempt and the completion marker, and returns the result with correct answers and explanations.

**Not deployed.** Deploying Cloud Functions requires the Blaze plan (billing card). Do not deploy until you have
approved that. The root `firebase.json` intentionally has no `functions` block, so a normal `firebase deploy` cannot
deploy it by accident.

- Tests (no Firebase needed): `cd functions && npm install && npm test`
- To deploy later (after approving Blaze): add `"functions": [{ "source": "functions", "codebase": "default" }]` to
  `firebase.json`, then `npx firebase deploy --only functions`.
- Safety settings already in code: `maxInstances: 5` (caps parallelism and worst-case cost), 30 s timeout, 256 MiB.
- Idempotent: the same `clientAttemptId` always returns the same attempt, so network retries never double-count.
- Region `asia-south1` must match the region you pick for Firestore/functions in the Flutter app (`services.dart`).
