# RankSet student app (Android)

## Local demo preview

The preview uses the existing student app screens, Firebase Auth and Firestore emulators, and the
repository's sample exam and quiz. It needs no Firebase project or billing account. The app shows a
`LOCAL DEMO PREVIEW` banner when this mode is enabled. The demo account and its data exist only in
the local emulators.

From the repository root, start the emulators in one terminal:

```powershell
npm run emulators -- --config firebase.preview.json --only auth,firestore --project demo-rankset
```

In a second terminal, seed the local demo data:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8180'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9199'
npm run seed:emulator
```

On a connected Android phone on the same network as the computer, launch the student app. This
machine's current Wi-Fi address is `10.22.188.226`; use the computer's current LAN IPv4 address if
it changes:

```powershell
cd apps/student
flutter run -d 6HFAGYUSPBRSEU8P --dart-define=LOCAL_PREVIEW=true --dart-define=EMULATOR_HOST=10.22.188.226 --dart-define=AUTH_EMULATOR_PORT=9199 --dart-define=FIRESTORE_EMULATOR_PORT=8180 --dart-define=SCORING_MODE=client
```

Sign in with `student@rankset.test` / `Passw0rd!demo`. `SCORING_MODE=client` is used only for this
local demo flow; mode B emulator rules are selected by the separate `firebase.preview.json` preview config. The preview supports
the seeded exam, quiz, language preference, and local quiz history. Google sign-in and cloud-backed
accounts are not part of the preview.

To run without the local demo mode, configure real Firebase options first (the checked-in
`lib/firebase_options.dart` is intentionally a placeholder), then run:

```powershell
cd apps/student
flutter run -d 6HFAGYUSPBRSEU8P
```

## Checks

```powershell
cd apps/student
flutter analyze
cd ../../packages/rankset_core
flutter analyze
flutter test
```
