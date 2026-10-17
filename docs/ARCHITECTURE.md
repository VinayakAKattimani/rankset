# RankSet: Architecture, Data Model, Access Control and Plan

Status: Increment 2. Backend foundation + shared Flutter package + student app + scoring function written. Nothing has been deployed, no Firebase project created, no billing enabled. Flutter code has NOT been compiled (no SDK in the build environment).

## 1. Scope (agreed MVP)

In: student register/login/logout (Google + email/password), exam > subject > topic browsing,
one-question-at-a-time quizzes with free navigation and answer changes, submit, result with correct answers and
explanations, saved attempts and history, English + Hindi content (more languages later),
private admin web dashboard (catalog + quiz/question CRUD, translations, review and publish, view students/results).

Out: payments, subscriptions, ads, leaderboards, streaks, badges, push notifications, chatbot/AI features,
separate current-affairs module, notes/PDF, advanced analytics. (Earlier design pages for these are parked, not deleted.)

## 2. Stack and project structure

Stack (unchanged from earlier decision): Flutter + Firebase (Auth, Firestore). Student app = Android.
Admin dashboard = Flutter Web in the same Firebase project, hosted on Firebase Hosting (Spark plan supports Hosting).

```
rankset/
  docs/                    this file, setup guide, test status
  rules/                   template.rules + mode-a.rules + mode-b.rules  (single source of truth)
  firestore.rules          GENERATED, mode A
  rules/dist/              GENERATED, mode B fallback
  firestore.indexes.json
  firebase.json            Firestore + emulators (no Functions block on purpose)
  scripts/                 build-rules, set-admin, export/import-backup, seed-demo
  tests/unit, tests/rules  unit tests (run) and emulator rules tests (you run)
  packages/rankset_core/   shared Dart: theme (agreed colours/fonts), models, scoring, Firestore repositories   [written, not compiled]
  apps/student/            Flutter Android app                                                              [written, not compiled]
  functions/               Cloud Function for scoring, mode A. Unit tested (11 tests pass). NOT deployed: needs Blaze
  --- later increment ---
  apps/admin/              Flutter Web admin dashboard
```

Visual design is reused as agreed: indigo `#3F3D9E`, saffron `#FF9933`, off-white `#F7F8FC`, green `#2E9E5B`,
red `#D64545`, text `#1F2230`, dark mode background `#12131A`; Noto Sans Devanagari + Poppins;
56 dp option buttons, 14 dp corners. Streak/leaderboard/premium/ads pieces are not built.

Branding: the app name will live in one constant (`AppBrand.name = 'RankSet'`) in `rankset_core` and in the
Android `app_name` string, so renaming later touches two places. Firebase project IDs and package names are
technical identifiers and are NOT tied to the brand.

## 3. Data model (Firestore)

Languages are keyed by code (`en`, `hi`, plus `bn ta te mr gu kn ml pa` already allowed by the rules).
English is required, everything else optional. Adding a language needs no schema change.

| Collection | Doc id | Fields | Who reads | Who writes |
|---|---|---|---|---|
| `categories` | auto | `name{lang}`, `order`, `isPublished`, `updatedAt`, `updatedBy` | signed-in: published only; admin: all | admin |
| `exams` | auto | `categoryId`, `name`, `order`, `isPublished`, audit | same | admin |
| `subjects` | auto | `examId`, `name`, `order`, `isPublished`, audit | same | admin |
| `topics` | auto | `examId`, `subjectId`, `name`, `order`, `isPublished`, audit | same | admin |
| `quizzes` | auto | `examId`, `subjectId`, `topicId`, `title{lang}`, `languages[]`, `status`, `questionIds[]`, `questionCount`, `createdBy`, `lastEditedBy`, `reviewedBy`, `reviewedAt`, `publishedAt`, `updatedAt` | signed-in: `status == published`; admin: all | admin (lifecycle enforced) |
| `quizzes/{id}/questions/{qid}` | **stable question id** | `order`, `translations{lang:{text, options[4]}}`, audit | published quizzes: any signed-in; admin: all | admin, only while quiz is `draft` |
| `quizzes/{id}/answerKeys/{qid}` | same `qid` | `correctIndex 0-3`, `explanations{lang}`, audit | admin; student only after completing that quiz | admin, only while `draft` |
| `attempts/{id}` | `{uid}_{clientAttemptId}` (mode A) / auto (mode B) | `uid`, `quizId`, `quizTitle{lang}` (so History needs no extra reads), `examId`, `subjectId`, `topicId`, `language`, `startedAt`, `submittedAt`, `responses{qid: index}` (answered questions only), `score`, `total`, `correct`, `wrong`, `unanswered`, `scoreSource` (`server`, or in mode B `pending` then `client`) | owner; admin | server (mode A) / validated client (mode B). Mode A: never editable. Mode B: one finalising update |
| `users/{uid}` | auth uid | `displayName`, `email`, `preferredLanguage`, `createdAt` (no role field) | owner; admin | owner (limited fields) |
| `users/{uid}/completed/{quizId}` | quiz id | `attemptId`, `completedAt` | owner; admin | server (mode A) / batch-validated client (mode B) |
| `config/review` | fixed | `requireDifferentReviewer` | admin | Console or script only |

Design choices and reasons:
- **Stable question identity**: the question id is the document id and the key in `responses`, `questionIds` and
  `answerKeys`. Translations live inside the question, so Hindi and English can never drift apart.
- **Answers and explanations are in a separate collection** so the app can read questions without ever receiving
  the answers. Explanations reveal the answer, so they are in the key document too.
- **Responses are a map inside the attempt**, not one document each. One write per attempt keeps us inside the
  free 20,000 writes/day.
- **No in-progress documents**: answers are kept on the phone until Submit. (If the app is killed mid-quiz, the
  quiz restarts. Local save can be added later without any schema change.)
- Quiz is language-flexible: `languages[]` says which languages are complete; the app only offers those.

## 4. Access control

Roles: student (any signed-in user) and admin. There is no role field in any user-writable document.

Admin = Firebase Auth **custom claim** `admin: true` + verified email.
- Claims can only be set with the Admin SDK. `scripts/set-admin.js` does this from your trusted machine using
  your own Google login (Application Default Credentials). No Cloud Function and no billing needed.
- Rules check `request.auth.token.admin == true && email_verified == true`. A client cannot edit its token.
- Revoking removes the claim and revokes refresh tokens (existing tokens may work up to 1 hour).
- Both admins sign in with Google (verified email by construction). The dashboard hides admin screens from
  non-admins for convenience only; the rules are the real protection.

Quiz lifecycle, enforced by rules (`quizTransitionOk`):

```
draft --submit--> in_review --approve--> published --unpublish--> unpublished --reopen--> draft
                     |  \--send back--> draft
```
- Only `draft` content can be edited (quiz fields, questions, answer keys).
- `draft -> in_review` freezes content (only status fields may change). `questionCount >= 1` required.
- `in_review -> published` requires `reviewedBy == your uid` and, by default, **a different admin than the last
  editor** (`config/review.requireDifferentReviewer`, anything other than explicit `false` means enforced).
  This is the "human review before publishing" control. You can relax it to `false` if only one of you is working.
- Published content cannot be changed; unpublish, reopen as draft, edit, review again.
- Rules cannot verify that every id in `questionIds` has a question and a key document. The admin dashboard
  must run that completeness check before enabling "Submit for review" (planned in increment 4).

Student rules: read published catalog/quizzes/questions; own profile (name + language only); own attempts;
answer keys only for quizzes they completed. Queries must filter (`isPublished == true`, `uid == me`).
Everything not listed is denied by default.

Account deletion: students may delete their own user doc, attempts and markers. Google Play requires an in-app
way to delete accounts for apps that create them; confirm the current policy text before publishing.

## 5. Which operations really need Cloud Functions (verified)

| Operation | Needs Functions? | How we do it |
|---|---|---|
| Trusted score calculation with hidden answers | **Yes** (mode A) | Cloud Function, or the fallback in section 6 |
| Setting admin claims | No | `scripts/set-admin.js` (Admin SDK, local) |
| Review/publish workflow | No | Security rules |
| Releasing answer keys after submit | No | Rules (`completed` marker) |
| Backups | Managed backups and gcloud export need billing | `scripts/export-backup.js` (free, local JSON) |
| Account deletion, history, results views | No | Client + rules |

Pricing and plan facts I verified today (Oct 2026) from Google and third-party pages:
- Cloud Functions require the **Blaze** (pay-as-you-go) plan; it needs a billing account. Blaze keeps the same free
  quotas as Spark, with a free invocation allowance (about 2 million/month per sources I found), but it has
  **no hard spending cap**. Budget alerts only notify, they do not stop spending. Deployments also use Cloud
  Build and Artifact Registry, which have their own small allowances.
- Cloud Storage for Firebase now needs Blaze (since 3 Feb 2026). RankSet MVP stores no files, so this does not affect us.
- Firestore free quota (Spark and Blaze): 1 GiB stored, 50,000 reads/day, 20,000 writes/day, 20,000 deletes/day,
  10 GiB egress/month. On Spark, going over a quota restricts the product instead of charging.
- Security-rule `get()`/`exists()` calls are billed as reads. We use few of them (quiz status on question reads,
  completion marker on key reads, plus admin writes).
- Authentication with Google and email/password is free. We do not use phone auth (SMS costs money).
- Scheduled Firestore backups and import/export need billing; managed backups likewise.

Rough capacity on Spark (my estimate, not a measurement): a full quiz journey (browse, start 10 questions,
submit, review answers, history) is roughly 40-50 document reads including rule lookups, so about 1,000 complete
journeys per day before hitting 50,000 reads. Bundling questions into one document later would raise that a lot.

## 6. DECISION NEEDED: how to score on the backend

Your rule: do not enable Blaze without approval. The brief wants the **backend** to calculate and save the score,
and the correct answers must not reach the phone before submit.

**Option A (recommended): Cloud Function on Blaze.** Student calls `submitAttempt(quizId, language, responses)`.
The function reads answer keys with the Admin SDK, computes the score, writes `attempts/{id}` and the `completed`
marker, and returns the result with correct answers and explanations. Clients cannot write attempts at all.
- Cost: needs a billing card. At MVP volume I expect Rs 0, but there is no hard cap. Mitigation: budget alert at a
  tiny amount (for example Rs 100), alerts to both of you, review usage weekly, and App Check later to block
  non-app traffic.
- Meets definition-of-done step 7 exactly. Rules file: `firestore.rules` (already generated).

**Option B (fallback, Rs 0, no card): rules-gated, phone computes the score.** Flow: (1) the student writes a
`pending` attempt (answers, no score) and the completion marker in one batch; rules check ownership, a published
quiz, real question ids and a matching quiz title. (2) The marker unlocks the answer keys. (3) The phone computes
the score. (4) The phone finalises the attempt once (`pending` -> `client`); rules allow only the score fields to
change and require correct+wrong to equal the number of answered questions, so the score can never exceed what was
answered. (An earlier draft of mode B required the score before the keys were readable, which could not work; fixed.)
- Weakness: a determined user can forge their own stored score, because rules cannot compute a score. Since there is
  no leaderboard or reward, the damage is limited to their own history. The admin dashboard can recompute the real
  score from `responses` + answer keys, so you can always see the truth.
- Does NOT literally satisfy "backend calculates the score". Rules file: `rules/dist/firestore.modeB.rules`.

**Option C: scoring on a different free host (a small Node service outside Firebase).** Not recommended: second
vendor, a service-account secret to protect, cold starts, and I have not verified any host's current free-tier or
usage terms. Not built.

Switching B -> A later needs no data migration: same collections, same ids. You deploy the function and swap the
rules file; the student app changes one repository class.

## 7. Implementation plan

1. Backend foundation: rules (both modes), indexes, admin/backup tooling, seed data, tests. **Done (increment 1).**
2. Scoring: Cloud Function for mode A with tests **written and passing**; mode B client path written. Both sit behind
   one `AttemptRepository` interface, chosen at build time (`--dart-define=SCORING_MODE=server|client`).
   **Deploying the function still needs your decision on section 6.**
3. `rankset_core` Dart package: theme from agreed colours/fonts, models, scoring, repositories. **Written, not compiled.**
4. Student app: auth, browse, quiz player (navigate, change answers, submit), result with explanations, history,
   profile (language, sign out, delete account), online-only gate. **Written, not compiled.**
5. Admin web (next): Google sign-in gate, catalog CRUD, quiz + question editor with translations, completeness check,
   review/publish, student and result views.
6. Integration: emulator end-to-end run through all 10 definition-of-done steps, fixes, hardening
   (App Check optional), backup routine, publishing checklist (privacy policy, account deletion, Play listing).

## 8. Not decided / not verified

- RankSet trademark, domain and Play Store name availability: not checked.
- No domain purchase, no Play Console account, no Firebase project creation has been done for you.
- Content (questions, notes) must be written or verified by a human before publishing; AI drafts are fine, AI is
  never a student-facing feature.
