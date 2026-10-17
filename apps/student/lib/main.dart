import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services.dart';

// Build-time switches (flutter run --dart-define=NAME=value):
//   SCORING_MODE=server (default, mode A, needs the Cloud Function) | client (mode B, free fallback)
//   USE_EMULATOR=true   connect to the local Firebase emulators
//   EMULATOR_HOST=10.0.2.2 (Android emulator default; use your PC's LAN IP for a real phone)
const String _scoringMode =
    String.fromEnvironment('SCORING_MODE', defaultValue: 'server');
const bool _localPreview = bool.fromEnvironment('LOCAL_PREVIEW');
const bool _useEmulator = bool.fromEnvironment('USE_EMULATOR') || _localPreview;
const String _emulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
const int _authEmulatorPort =
    int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);

// Emulator-only configuration. These values identify the local demo app; they are not cloud
// credentials and are never used unless LOCAL_PREVIEW=true.
const FirebaseOptions _localFirebaseOptions = FirebaseOptions(
  apiKey: 'local-demo-api-key',
  appId: '1:1234567890:android:ranksetlocaldemo',
  messagingSenderId: '1234567890',
  projectId: 'demo-rankset',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: _localPreview
        ? _localFirebaseOptions
        : DefaultFirebaseOptions.currentPlatform,
  );

  // RankSet is online-only: do not cache data on the phone.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: false);

  if (_useEmulator) {
    FirebaseFirestore.instance
        .useFirestoreEmulator(_emulatorHost, _firestoreEmulatorPort);
    await FirebaseAuth.instance
        .useAuthEmulator(_emulatorHost, _authEmulatorPort);
    FirebaseFunctions.instanceFor(region: 'asia-south1')
        .useFunctionsEmulator(_emulatorHost, 5001);
  }

  runApp(RankSetApp(
      services: Services.create(clientScoring: _scoringMode == 'client')));
}
