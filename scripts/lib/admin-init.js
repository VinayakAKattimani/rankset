import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';

// Uses Application Default Credentials (run `gcloud auth application-default login`),
// or GOOGLE_APPLICATION_CREDENTIALS. When the emulator env vars are set, no credentials are needed.
export function initAdmin(projectId) {
  if (!projectId) throw new Error('Missing --project=<firebase-project-id>');
  if (getApps().length) return getApps()[0];
  const usingEmulator = !!(process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST);
  return initializeApp(usingEmulator ? { projectId } : { projectId, credential: applicationDefault() });
}

export function parseArgs(argv) {
  const flags = {};
  const positional = [];
  for (const a of argv) {
    if (a.startsWith('--')) { const [k, v] = a.slice(2).split('='); flags[k] = v ?? true; }
    else positional.push(a);
  }
  return { flags, positional };
}

export function isEmulator() {
  return !!process.env.FIRESTORE_EMULATOR_HOST;
}
