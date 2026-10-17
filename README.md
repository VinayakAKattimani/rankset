# RankSet

Competitive-exam quiz and practice platform for India. Tagline (provisional): **Practice. Improve. Rise.**

RankSet is the preferred working name. Trademark, domain and app-store availability have NOT been verified.
The name is kept in one place per app (see `docs/ARCHITECTURE.md`, "Branding") so it is easy to change.

## Status

Increment 2: backend foundation, scoring function (tested, not deployed), shared Flutter package and student app
(written, NOT yet compiled). Admin web dashboard is next.

## Read first

1. `docs/ARCHITECTURE.md` - structure, data model, access control, cost findings, plan, decisions waiting on you
2. `docs/SETUP_AND_E2E.md` - exact commands to set up, test and verify on your machine
3. `docs/TEST_STATUS.md` - what was actually run vs what you must run

## Quick start

```
npm install
npm run build:rules
npm run test:unit
npm run test:rules        # needs Java; starts the Firestore emulator
```
