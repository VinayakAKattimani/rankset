import { test } from 'node:test';
import assert from 'node:assert/strict';
import { encodeValue, decodeValue } from '../../scripts/lib/serialize.js';

class FakeTimestamp {
  constructor(s) { this.seconds = s; }
  toDate() { return new Date(this.seconds * 1000); }
  static fromDate(d) { return new FakeTimestamp(Math.floor(d.getTime() / 1000)); }
}
const fakeDb = { doc: (p) => ({ path: p, collection() {} }) };

test('timestamps round trip', () => {
  const enc = encodeValue({ at: new FakeTimestamp(1_700_000_000) });
  assert.equal(enc.at.__type, 'timestamp');
  const dec = decodeValue(JSON.parse(JSON.stringify(enc)), { Timestamp: FakeTimestamp, db: fakeDb });
  assert.equal(dec.at.seconds, 1_700_000_000);
});

test('nested maps, arrays, null and unicode survive', () => {
  const input = { a: [1, { b: 'नमस्ते' }], c: null, d: { e: [true, false] } };
  const out = decodeValue(JSON.parse(JSON.stringify(encodeValue(input))), { Timestamp: FakeTimestamp, db: fakeDb });
  assert.deepEqual(out, input);
});

test('document refs round trip', () => {
  const ref = { path: 'quizzes/q1', collection() {} };
  const enc = encodeValue({ ref });
  assert.deepEqual(enc.ref, { __type: 'ref', path: 'quizzes/q1' });
  assert.equal(decodeValue(enc, { Timestamp: FakeTimestamp, db: fakeDb }).ref.path, 'quizzes/q1');
});
