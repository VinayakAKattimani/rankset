// Free-plan backup: reads every document and writes one JSON file on YOUR machine.
//   node scripts/export-backup.js --project=my-project-id
// Costs Firestore reads (1 per document) against the free daily quota. Managed backups
// and gcloud export need the Blaze plan, so this script is the Spark-friendly option.
import { mkdirSync, writeFileSync } from 'node:fs';
import { getFirestore } from 'firebase-admin/firestore';
import { initAdmin, parseArgs } from './lib/admin-init.js';
import { encodeValue } from './lib/serialize.js';

const { flags } = parseArgs(process.argv.slice(2));
initAdmin(flags.project);
const db = getFirestore();
const docs = [];

async function walk(colRef) {
  const snap = await colRef.get();
  for (const d of snap.docs) {
    docs.push({ path: d.ref.path, data: encodeValue(d.data()) });
    for (const sub of await d.ref.listCollections()) await walk(sub);
  }
}

const roots = await db.listCollections();
for (const c of roots) await walk(c);
mkdirSync('backups', { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const file = `backups/rankset-${flags.project}-${stamp}.json`;
writeFileSync(file, JSON.stringify({ exportedAt: new Date().toISOString(), projectId: flags.project, count: docs.length, documents: docs }, null, 2));
console.log(`Exported ${docs.length} documents to ${file} (used about ${docs.length} reads).`);
console.log('Store this file somewhere safe and private. It contains student emails.');
