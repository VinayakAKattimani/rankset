// Restore a backup made by export-backup.js. DRY RUN by default.
//   node scripts/import-backup.js backups/file.json --project=my-project-id          (dry run)
//   node scripts/import-backup.js backups/file.json --project=my-project-id --apply  (writes)
// Existing documents with the same path are overwritten. Auth users are NOT part of this backup.
import { readFileSync } from 'node:fs';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { initAdmin, parseArgs } from './lib/admin-init.js';
import { decodeValue } from './lib/serialize.js';

const { flags, positional } = parseArgs(process.argv.slice(2));
const [file] = positional;
if (!file) { console.error('Usage: node scripts/import-backup.js <file.json> --project=<id> [--apply]'); process.exit(1); }
initAdmin(flags.project);
const db = getFirestore();
const backup = JSON.parse(readFileSync(file, 'utf8'));
console.log(`Backup from ${backup.exportedAt} (project ${backup.projectId}), ${backup.count} documents.`);
if (!flags.apply) { console.log('Dry run only. Add --apply to write.'); process.exit(0); }
if (backup.projectId !== flags.project && !flags.force) {
  console.error(`Backup is from "${backup.projectId}" but target is "${flags.project}". Add --force if intended.`);
  process.exit(1);
}
let batch = db.batch(); let n = 0; let total = 0;
for (const d of backup.documents) {
  batch.set(db.doc(d.path), decodeValue(d.data, { Timestamp, db }));
  n++; total++;
  if (n === 400) { await batch.commit(); batch = db.batch(); n = 0; }
}
if (n) await batch.commit();
console.log(`Restored ${total} documents.`);
