// Mode A: server-side scoring. Run with: npm run test:rules:a
import { describe, it, before, after, beforeEach } from 'node:test';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { makeEnv, seed, asAdmin, asStudent, assertFails, assertSucceeds, Timestamp } from './helpers.js';
import { registerCommonTests } from './common.js';

let testEnv;
before(async () => { testEnv = await makeEnv('A'); });
after(async () => { await testEnv?.cleanup(); });

registerCommonTests('A', () => testEnv);

describe('[mode A] attempts are written by the server only', () => {
  const attempt = (uid) => ({ uid, quizId: 'qzPub', language: 'en', score: 2, total: 2, submittedAt: Timestamp.now() });
  beforeEach(async () => {
    await seed(testEnv);
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'attempts/mine'), attempt('student1'));
      await setDoc(doc(ctx.firestore(), 'attempts/theirs'), attempt('student2'));
    });
  });

  it('students cannot create or edit attempts, even with a perfect score', async () => {
    await assertFails(setDoc(doc(asStudent(testEnv), 'attempts/fake'), attempt('student1')));
    await assertFails(updateDoc(doc(asStudent(testEnv), 'attempts/mine'), { score: 99 }));
  });
  it('students cannot create their own completion marker (which would unlock answer keys)', async () => {
    await assertFails(setDoc(doc(asStudent(testEnv), 'users/student1/completed/qzPub'), { attemptId: 'x', completedAt: Timestamp.now() }));
    await assertFails(getDoc(doc(asStudent(testEnv), 'quizzes/qzPub/answerKeys/q1')));
  });
  it('students read only their own attempts; admins read all', async () => {
    await assertSucceeds(getDoc(doc(asStudent(testEnv), 'attempts/mine')));
    await assertFails(getDoc(doc(asStudent(testEnv), 'attempts/theirs')));
    await assertSucceeds(getDoc(doc(asAdmin(testEnv), 'attempts/theirs')));
  });
  it('students can delete their own attempts (account deletion) but not others', async () => {
    await assertSucceeds(deleteDoc(doc(asStudent(testEnv), 'attempts/mine')));
    await assertFails(deleteDoc(doc(asStudent(testEnv), 'attempts/theirs')));
  });
});
