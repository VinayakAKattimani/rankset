// Builds Firestore rules for a scoring mode from rules/template.rules + rules/mode-*.rules.
//   node scripts/build-rules.js            -> writes firestore.rules (mode A) and rules/dist/firestore.modeB.rules
//   node scripts/build-rules.js --mode=B --out=firestore.rules   -> one build, chosen output
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const MARKER = '//__MODE_RULES__';

export function buildRules(mode) {
  const m = String(mode).toUpperCase();
  if (m !== 'A' && m !== 'B') throw new Error(`Unknown mode "${mode}" (use A or B)`);
  const template = readFileSync(resolve(root, 'rules/template.rules'), 'utf8');
  const part = readFileSync(resolve(root, `rules/mode-${m.toLowerCase()}.rules`), 'utf8');
  if (!template.includes(MARKER)) throw new Error('Template is missing the mode marker');
  const name = m === 'A' ? 'A (server-side scoring via Cloud Function)' : 'B (fallback, client-computed score, no Cloud Functions)';
  return template.replace('__MODE_NAME__', name).replace(MARKER, part.trimEnd());
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const args = Object.fromEntries(process.argv.slice(2).filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('=')));
  if (args.mode) {
    const out = resolve(root, args.out ?? 'firestore.rules');
    writeFileSync(out, buildRules(args.mode));
    console.log(`Wrote mode ${args.mode.toUpperCase()} rules to ${out}`);
  } else {
    writeFileSync(resolve(root, 'firestore.rules'), buildRules('A'));
    writeFileSync(resolve(root, 'rules/dist/firestore.modeB.rules'), buildRules('B'));
    console.log('Wrote firestore.rules (mode A) and rules/dist/firestore.modeB.rules (mode B)');
  }
}
