# Setup, local testing and verification (run these on your machine)

Prerequisites: Node.js 20+, Java (JDK 21+ recommended, the Firebase CLI tells you if yours is too old), Git.
Nothing below needs a credit card.

## A. Run the checks that do not need a Firebase account

```
npm install
npm run build:rules        # regenerates firestore.rules (mode A) and rules/dist/firestore.modeB.rules
npm run test:unit          # 10 tests, no network, no Java
npm run test:rules         # starts the Firestore emulator; runs mode A then mode B rules tests
```
Expected: unit tests all pass; rules tests print passing results for both modes. The first emulator run downloads a
JAR file, so it needs internet. If any rules test fails, send me the failing test name and message.

Also run the scoring function tests: `cd functions && npm install && npm test` (11 tests, no Firebase needed).

## B. Try it by hand in the emulators

```
npm run emulators          # terminal 1: Auth 9099, Firestore 8080, UI http://localhost:4000
npm run seed:emulator      # terminal 2: demo catalog + one published quiz + 3 demo users
```
Demo logins (emulator only), password `Passw0rd!demo`: admin1@rankset.test, admin2@rankset.test, student@rankset.test.
In the Emulator UI you can inspect the data. To run the student app against the emulators (mode B, free), follow
`apps/student/README.md`. The admin dashboard comes in the next increment.

## C. Create the real Firebase project (free Spark plan) - only when you are ready

1. Firebase Console > Add project > name it (for example `rankset-prod`). Do NOT click any "upgrade" prompt.
2. Build > Authentication > Get started > enable **Google** and **Email/Password**. Do not enable Phone.
3. Build > Firestore Database > Create database (production mode, pick an Indian region such as `asia-south1`; the
   location cannot be changed later).
4. Confirm billing is off: Project settings > Usage and billing should show the **Spark** plan.
5. Copy `.firebaserc.example` to `.firebaserc` and put your project id in it.
6. Deploy rules and indexes (these are free on Spark):
   `npx firebase login` then `npx firebase deploy --only firestore:rules,firestore:indexes`
   (Deploys mode A rules. Until a scoring path exists, students cannot submit attempts. Use
   `npm run build:rules -- --mode=B --out=firestore.rules` first if you want the no-cost fallback.)
7. Create the review setting once: Console > Firestore > Start collection `config` > document id `review` > field
   `requireDifferentReviewer` (boolean) = `true`.

## D. Make you and your sister admins

1. Each of you signs in once with Google (the admin dashboard will do this; until then, Authentication > Users > Add user).
2. Install the Google Cloud CLI, then run `gcloud auth application-default login` with your own Google account.
3. `npm run admin -- grant you@gmail.com --project=YOUR_PROJECT_ID`
   `npm run admin -- grant sister@gmail.com --project=YOUR_PROJECT_ID`
4. `npm run admin -- list --project=YOUR_PROJECT_ID` to confirm. Sign out and in again to refresh the token.
Never create or commit a service-account key file. If you must use one, keep it outside the repo.

## E. Backups on the free plan

`npm run backup:export -- --project=YOUR_PROJECT_ID` writes `backups/rankset-<project>-<time>.json` (about one read per
document). Run it weekly and after big content sessions; copy the file to private storage (it holds student emails).
Restore: `npm run backup:import -- backups/FILE.json --project=ID` is a dry run; add `--apply` to write. Auth users are
not in this backup; students can sign in again with the same Google/email accounts.

## F. End-to-end verification (definition of done)

Steps 1-3 and 9-10 can be checked at the data/permission level now with the emulator rules tests. The full flow
needs the apps (increments 4-5), after which this table is the sign-off checklist.

| # | Step | How to verify | Possible now? |
|---|---|---|---|
| 1 | Admin creates exam, subject, topic, quiz | Admin dashboard (later); rules tests cover permissions | Rules only |
| 2 | Admin adds questions, options, answers, explanations | Dashboard; rules tests cover validation | Rules only |
| 3 | Different admin reviews and publishes | Rules test "draft -> review -> publish needs a DIFFERENT admin" | Rules only |
| 4 | Student registers and logs in | Student app | Later |
| 5 | Student selects exam and starts quiz | Student app | Later |
| 6 | Student answers and submits | Student app | Later |
| 7 | Backend calculates and saves result | Needs section 6 decision | Later |
| 8 | Student sees score, explanations, history | Student app | Later |
| 9 | Admin reviews saved result | Dashboard; rules tests cover read access | Rules only |
| 10 | Unauthorised users blocked from admin functions | Rules tests (signed-out, student, unverified admin) | **Now** |
