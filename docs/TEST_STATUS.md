# Test status

## Run in the build environment (passed)

| Test file | What it checks | Result |
|---|---|---|
| tests/unit/build-rules.test.js | Both rule sets build, brackets balanced, no placeholders, mode A blocks client attempts, mode B validates them, committed generated files match the sources | 5 passed |
| tests/unit/demo-data.test.js | Demo questions: unique stable ids, 4 distinct options per language, valid answer index, English+Hindi explanations, consistent catalog links | 2 passed |
| tests/unit/serialize.test.js | Backup encode/decode of timestamps, refs, nested data, Hindi text | 3 passed |
| functions/tests/submit-attempt.test.js | Scoring function with a fake database: perfect/mixed scores, language fallback, attempt + marker written, idempotent retry, signed-out/invalid/unknown answers, unpublished/missing/wrong-language quiz, missing answer key, startedAt clamping | 11 passed |

Also checked: `node --check` syntax on all test files; `npm install` resolved (firebase-admin 13.10, firebase 11.10,
@firebase/rules-unit-testing 4.0.1, firebase-tools 14.27).

## Written but NOT run (you must run them)

The Firestore emulator could not start in the build environment: its download host (storage.googleapis.com) is
blocked there. Flutter's SDK downloads come from the same host.

| Command | Covers | Status |
|---|---|---|
| `npm run test:rules:a` | Catalog, users, quiz lifecycle and review, questions, answer-key gating, config, mode A attempts | Not run |
| `npm run test:rules:b` | Same common suite + mode B: pending attempt + marker batch, key unlock, one-time finalise, forged title/score/other-user cases | Not run |
| `cd packages/rankset_core && flutter test` | LocalizedText, quiz/question parsing, ScoreCalculator, star thresholds, function-response parsing | Not run (no Flutter SDK here) |

Rules syntax has not been machine-checked by Google's compiler. Treat the first emulator run as the real verification
and send me any failures.

## Flutter code

`packages/rankset_core` and `apps/student` were written without a Flutter or Dart SDK (pub.dev and the SDK download host are
blocked in the build environment). I did only crude checks: every local import resolves and brackets balance. The code has
not been compiled or analysed. Expect a few compile errors or analyzer warnings on the first `flutter pub get` / `flutter run`,
and send me the output. No UI screenshots exist yet for the same reason.

## Not testable yet

Scripts that talk to Firebase (`set-admin`, `seed-demo`, `export-backup`, `import-backup`) were syntax-checked only.
Admin dashboard does not exist yet. The scoring function is tested only against a fake database, not the real Firestore.
