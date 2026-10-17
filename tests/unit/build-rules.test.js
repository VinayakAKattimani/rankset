import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { buildRules } from '../../scripts/build-rules.js';

const balanced = (s) => {
  const noStr = s.replace(/'[^']*'/g, "''").replace(/\/\/.*$/gm, '');
  let depth = 0;
  for (const ch of noStr) {
    if ('{(['.includes(ch)) depth++;
    if ('})]'.includes(ch)) depth--;
    if (depth < 0) return false;
  }
  return depth === 0;
};

for (const mode of ['A', 'B']) {
  test(`mode ${mode} builds with balanced brackets and no placeholders`, () => {
    const out = buildRules(mode);
    assert.ok(balanced(out), 'unbalanced brackets');
    assert.ok(!out.includes('__MODE'), 'placeholder left over');
    assert.ok(out.startsWith("rules_version = '2';"));
  });
}

test('mode A blocks client attempt writes; mode B validates client attempts', () => {
  const a = buildRules('A');
  const b = buildRules('B');
  assert.match(a, /match \/attempts\/\{attemptId\}[\s\S]*allow create, update: if false;/);
  assert.ok(!a.includes('scoreSource'));
  assert.ok(!a.includes('validFinalize'));
  assert.ok(b.includes("d.scoreSource == 'pending'"));
  assert.ok(b.includes('validFinalize'));
});

test('security-critical rules are present in both modes', () => {
  for (const mode of ['A', 'B']) {
    const out = buildRules(mode);
    assert.ok(out.includes('request.auth.token.admin == true'));
    assert.ok(out.includes('request.auth.token.email_verified == true'));
    assert.ok(out.includes('match /answerKeys/{questionId}'));
    assert.ok(out.includes('allow write: if false;'), 'config must be client read-only');
  }
});

test('committed generated files are up to date', () => {
  assert.equal(readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'), buildRules('A'));
  assert.equal(readFileSync(new URL('../../rules/dist/firestore.modeB.rules', import.meta.url), 'utf8'), buildRules('B'));
});
