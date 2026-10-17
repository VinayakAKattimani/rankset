import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handleSubmitAttempt } from '../src/submit-attempt.js';
import { scoreAttempt, validateResponses, pickText, AppError } from '../src/scoring.js';

// Minimal in-memory Firestore stand-in.
function fakeDb(seed) {
  const store = new Map(Object.entries(seed));
  const ref = (path) => ({
    path,
    async get() { return { exists: store.has(path), data: () => structuredClone(store.get(path)) }; },
  });
  return {
    store,
    doc: ref,
    async getAll(...refs) { return Promise.all(refs.map((r) => r.get())); },
    async runTransaction(fn) {
      const writes = [];
      const tx = {
        get: (r) => r.get(),
        create: (r, d) => { if (store.has(r.path)) throw new Error('exists'); writes.push([r.path, d]); },
        set: (r, d) => { writes.push([r.path, d]); },
      };
      const out = await fn(tx);
      for (const [p, d] of writes) store.set(p, d);
      return out;
    },
  };
}

const quiz = {
  status: 'published', title: { en: 'Quiz', hi: 'क्विज़' }, languages: ['en', 'hi'],
  examId: 'e1', subjectId: 's1', topicId: 't1', questionIds: ['q1', 'q2', 'q3'],
};
const seed = () => ({
  'quizzes/z1': quiz,
  'quizzes/z1/answerKeys/q1': { correctIndex: 1, explanations: { en: 'E1', hi: 'ह1' } },
  'quizzes/z1/answerKeys/q2': { correctIndex: 2, explanations: { en: 'E2' } },
  'quizzes/z1/answerKeys/q3': { correctIndex: 0, explanations: { en: 'E3', hi: 'ह3' } },
});
const call = (db, data, uid = 'u1', now = new Date('2026-10-17T10:00:00Z')) => handleSubmitAttempt({ db, uid, data, now });
const base = { quizId: 'z1', language: 'en', clientAttemptId: 'abcdefgh1234', responses: { q1: 1, q2: 2, q3: 0 } };
const rejects = (p, code) => assert.rejects(p, (e) => e instanceof AppError && e.code === code);

test('perfect score', async () => {
  const r = await call(fakeDb(seed()), base);
  assert.deepEqual([r.score, r.total, r.correct, r.wrong, r.unanswered], [3, 3, 3, 0, 0]);
  assert.ok(r.results.every((x) => x.isCorrect));
});

test('mixed: wrong and unanswered counted, details returned in quiz order', async () => {
  const r = await call(fakeDb(seed()), { ...base, responses: { q1: 0, q3: 0 } });
  assert.deepEqual([r.correct, r.wrong, r.unanswered], [1, 1, 1]);
  assert.deepEqual(r.results.map((x) => x.questionId), ['q1', 'q2', 'q3']);
  assert.equal(r.results[1].selectedIndex, null);
  assert.equal(r.results[0].correctIndex, 1);
});

test('explanations use the requested language and fall back to English', async () => {
  const r = await call(fakeDb(seed()), { ...base, language: 'hi' });
  assert.equal(r.results[0].explanation, 'ह1');
  assert.equal(r.results[1].explanation, 'E2');
});

test('writes attempt and completion marker, server-owned fields set', async () => {
  const db = fakeDb(seed());
  const r = await call(db, base);
  const a = db.store.get(`attempts/${r.attemptId}`);
  assert.equal(a.uid, 'u1');
  assert.equal(a.scoreSource, 'server');
  assert.equal(a.score, 3);
  assert.deepEqual(a.quizTitle, quiz.title);
  assert.deepEqual(db.store.get('users/u1/completed/z1').attemptId, r.attemptId);
});

test('retrying the same clientAttemptId does not create a second attempt and returns the stored result', async () => {
  const db = fakeDb(seed());
  const first = await call(db, base);
  const attemptsBefore = [...db.store.keys()].filter((k) => k.startsWith('attempts/')).length;
  const second = await call(db, { ...base, responses: { q1: 0, q2: 0, q3: 1 } }); // different payload on retry
  assert.equal(second.attemptId, first.attemptId);
  assert.equal(second.score, 3, 'stored answers win');
  assert.equal([...db.store.keys()].filter((k) => k.startsWith('attempts/')).length, attemptsBefore);
});

test('rejects signed-out callers, bad ids, bad languages', async () => {
  const db = fakeDb(seed());
  await rejects(call(db, base, null), 'unauthenticated');
  await rejects(call(db, { ...base, clientAttemptId: 'x' }), 'invalid-argument');
  await rejects(call(db, { ...base, language: 'xx' }), 'invalid-argument');
  await rejects(call(db, { ...base, quizId: 'a/b' }), 'invalid-argument');
});

test('rejects unknown or invalid answers', async () => {
  const db = fakeDb(seed());
  await rejects(call(db, { ...base, responses: { q99: 1 } }), 'invalid-argument');
  await rejects(call(db, { ...base, responses: { q1: 4 } }), 'invalid-argument');
  await rejects(call(db, { ...base, responses: { q1: '1' } }), 'invalid-argument');
  await rejects(call(db, { ...base, responses: [1, 2] }), 'invalid-argument');
});

test('rejects unpublished, missing and wrong-language quizzes', async () => {
  const s = seed();
  s['quizzes/z2'] = { ...quiz, status: 'draft' };
  s['quizzes/z3'] = { ...quiz, languages: ['en'] };
  s['quizzes/z3/answerKeys/q1'] = s['quizzes/z1/answerKeys/q1'];
  const db = fakeDb(s);
  await rejects(call(db, { ...base, quizId: 'z2' }), 'failed-precondition');
  await rejects(call(db, { ...base, quizId: 'nope' }), 'not-found');
  await rejects(call(db, { ...base, quizId: 'z3', language: 'hi' }), 'invalid-argument');
});

test('missing answer key is a precondition failure, not a silent zero', async () => {
  const s = seed();
  delete s['quizzes/z1/answerKeys/q2'];
  await rejects(call(fakeDb(s), base), 'failed-precondition');
});

test('startedAt is clamped: future or very old values fall back to now', async () => {
  const now = new Date('2026-10-17T10:00:00Z');
  const db = fakeDb(seed());
  const r = await call(db, { ...base, startedAtMs: now.getTime() + 60_000 }, 'u1', now);
  assert.equal(db.store.get(`attempts/${r.attemptId}`).startedAt.getTime(), now.getTime());
  const db2 = fakeDb(seed());
  const r2 = await call(db2, { ...base, startedAtMs: now.getTime() - 5 * 60_000 }, 'u1', now);
  assert.equal(db2.store.get(`attempts/${r2.attemptId}`).startedAt.getTime(), now.getTime() - 5 * 60_000);
});

test('scoring helpers', () => {
  assert.equal(pickText({ en: 'a' }, 'hi'), 'a');
  assert.doesNotThrow(() => validateResponses({}, ['q1']));
  const s = scoreAttempt({ questionIds: ['a'], keysById: { a: { correctIndex: 3, explanations: { en: 'x' } } }, responses: { a: 3 }, language: 'en' });
  assert.equal(s.score, 1);
});
