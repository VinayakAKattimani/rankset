// Mode B (fallback, no Cloud Functions). Run with: npm run test:rules:b
import { describe, it, before, after, beforeEach } from 'node:test';
import { doc, getDoc, updateDoc, writeBatch } from 'firebase/firestore';
import { makeEnv, seed, asStudent, assertFails, assertSucceeds, serverTimestamp, Timestamp } from './helpers.js';
import { registerCommonTests } from './common.js';

let testEnv;
before(async () => { testEnv = await makeEnv('B'); });
after(async () => { await testEnv?.cleanup(); });

registerCommonTests('B', () => testEnv);

describe('[mode B] pending attempt, key unlock, one-time finalise', () => {
  beforeEach(() => seed(testEnv));
  // Student answered q1 (index 1) and q2 (index 0); quiz has 2 questions.
  const pending = (o = {}) => ({
    uid: 'student1', quizId: 'qzPub', quizTitle: { en: 'Quiz', hi: 'क्विज़' }, examId: 'exam1', subjectId: 'subj1', topicId: 'topic1', language: 'en',
    startedAt: Timestamp.now(), submittedAt: serverTimestamp(),
    responses: { q1: 1, q2: 0 }, score: 0, total: 2, correct: 0, wrong: 0, unanswered: 2, scoreSource: 'pending', ...o,
  });
  const marker = (attemptId = 'att1') => ({ attemptId, completedAt: serverTimestamp() });
  const submit = (db, a, m = marker(), quizId = 'qzPub') => {
    const batch = writeBatch(db);
    batch.set(doc(db, 'attempts/att1'), a);
    batch.set(doc(db, `users/student1/completed/${quizId}`), m);
    return batch.commit();
  };
  const finalize = (db, o = {}) => updateDoc(doc(db, 'attempts/att1'), { score: 1, correct: 1, wrong: 1, unanswered: 0, scoreSource: 'client', ...o });

  it('pending attempt + marker batch succeeds, then answer keys unlock', async () => {
    const db = asStudent(testEnv);
    await assertSucceeds(submit(db, pending()));
    await assertSucceeds(getDoc(doc(db, 'quizzes/qzPub/answerKeys/q1')));
  });
  it('a score cannot be supplied at creation', async () => {
    await assertFails(submit(asStudent(testEnv), pending({ score: 2, correct: 2, unanswered: 0 })));
    await assertFails(submit(asStudent(testEnv), pending({ scoreSource: 'client' })));
  });
  it('a marker without a real attempt is rejected', async () => {
    const db = asStudent(testEnv);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/student1/completed/qzPub'), marker('nope'));
    await assertFails(batch.commit());
  });
  it('attempts cannot be created for unpublished quizzes', async () => {
    await assertFails(submit(asStudent(testEnv), pending({ quizId: 'qzDraft' }), marker(), 'qzDraft'));
  });
  it('responses for unknown questions are rejected', async () => {
    await assertFails(submit(asStudent(testEnv), pending({ responses: { q1: 1, q99: 2 } })));
  });
  it('a forged quiz title is rejected', async () => {
    await assertFails(submit(asStudent(testEnv), pending({ quizTitle: { en: 'Something else' } })));
  });
  it('attempts for another user are rejected', async () => {
    await assertFails(submit(asStudent(testEnv), pending({ uid: 'student2' })));
  });
  it('finalise succeeds once with consistent counts', async () => {
    const db = asStudent(testEnv);
    await submit(db, pending());
    await assertSucceeds(finalize(db));
    await assertFails(finalize(db, { score: 2, correct: 2, wrong: 0 }));
  });
  it('finalise cannot claim more correct+wrong than questions answered', async () => {
    const db = asStudent(testEnv);
    await submit(db, pending({ responses: { q1: 1 } }));
    await assertFails(finalize(db, { score: 2, correct: 2, wrong: 0, unanswered: 0 }));
    await assertSucceeds(finalize(db, { score: 1, correct: 1, wrong: 0, unanswered: 1 }));
  });
  it('finalise cannot change anything except the score fields', async () => {
    const db = asStudent(testEnv);
    await submit(db, pending());
    await assertFails(finalize(db, { quizId: 'qzDraft' }));
    await assertFails(finalize(db, { responses: { q1: 1, q2: 1 } }));
  });
  it('another student cannot finalise someone else\'s attempt', async () => {
    await submit(asStudent(testEnv), pending());
    await assertFails(finalize(asStudent(testEnv, 'student2')));
  });
});
