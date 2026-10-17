// Tests that must pass in BOTH scoring modes. Called from modeA.test.js and modeB.test.js.
import { describe, it, beforeEach } from 'node:test';
import { doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where } from 'firebase/firestore';
import {
  seed, asAdmin, asStudent, asUnverifiedAdmin, asAnon, assertFails, assertSucceeds,
  serverTimestamp, Timestamp, loc, validQuestion, validKey, newQuiz,
} from './helpers.js';

export function registerCommonTests(mode, getEnv) {
  const env = () => getEnv();

  describe(`[mode ${mode}] catalog`, () => {
    beforeEach(() => seed(env()));

    it('signed-out users cannot read anything', async () => {
      await assertFails(getDoc(doc(asAnon(env()), 'categories/cat1')));
    });
    it('students read published categories but not unpublished ones', async () => {
      const db = asStudent(env());
      await assertSucceeds(getDoc(doc(db, 'categories/cat1')));
      await assertFails(getDoc(doc(db, 'categories/catHidden')));
    });
    it('student queries must filter on isPublished == true', async () => {
      const db = asStudent(env());
      await assertSucceeds(getDocs(query(collection(db, 'categories'), where('isPublished', '==', true))));
      await assertFails(getDocs(collection(db, 'categories')));
    });
    it('students cannot write catalog data', async () => {
      await assertFails(setDoc(doc(asStudent(env()), 'categories/x'), { name: loc('X'), order: 1, isPublished: true, updatedAt: serverTimestamp(), updatedBy: 'student1' }));
    });
    it('verified admin can create a valid category', async () => {
      await assertSucceeds(setDoc(doc(asAdmin(env()), 'categories/new1'), { name: loc('Banking', 'बैंकिंग'), order: 3, isPublished: false, updatedAt: serverTimestamp(), updatedBy: 'admin1' }));
    });
    it('admin with unverified email is rejected', async () => {
      await assertFails(setDoc(doc(asUnverifiedAdmin(env()), 'categories/new1'), { name: loc('Banking'), order: 3, isPublished: false, updatedAt: serverTimestamp(), updatedBy: 'admin9' }));
    });
    it('category without English name is rejected', async () => {
      await assertFails(setDoc(doc(asAdmin(env()), 'categories/new1'), { name: { hi: 'बैंकिंग' }, order: 3, isPublished: false, updatedAt: serverTimestamp(), updatedBy: 'admin1' }));
    });
    it('exam needs an existing category', async () => {
      const db = asAdmin(env());
      const data = (categoryId) => ({ categoryId, name: loc('RRB'), order: 2, isPublished: false, updatedAt: serverTimestamp(), updatedBy: 'admin1' });
      await assertFails(setDoc(doc(db, 'exams/e2'), data('missing')));
      await assertSucceeds(setDoc(doc(db, 'exams/e2'), data('cat1')));
    });
  });

  describe(`[mode ${mode}] users`, () => {
    beforeEach(() => seed(env()));
    const profile = (extra = {}) => ({ displayName: 'Priya', email: 'student1@rankset.test', preferredLanguage: 'hi', createdAt: serverTimestamp(), ...extra });

    it('student creates their own profile', async () => {
      await assertSucceeds(setDoc(doc(asStudent(env()), 'users/student1'), profile()));
    });
    it('student cannot create a profile for someone else', async () => {
      await assertFails(setDoc(doc(asStudent(env()), 'users/student2'), profile()));
    });
    it('student cannot sneak in a role field', async () => {
      await assertFails(setDoc(doc(asStudent(env()), 'users/student1'), profile({ role: 'admin' })));
      await assertFails(setDoc(doc(asStudent(env()), 'users/student1'), profile({ admin: true })));
    });
    it('student can change displayName and language but not email', async () => {
      await setDoc(doc(asStudent(env()), 'users/student1'), profile());
      const ref = doc(asStudent(env()), 'users/student1');
      await assertSucceeds(updateDoc(ref, { displayName: 'Priya S', preferredLanguage: 'en' }));
      await assertFails(updateDoc(ref, { email: 'other@x.com' }));
    });
    it('students cannot read other profiles; admins can', async () => {
      await env().withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/student2'), { displayName: 'B', preferredLanguage: 'en', createdAt: Timestamp.now() }));
      await assertFails(getDoc(doc(asStudent(env()), 'users/student2')));
      await assertSucceeds(getDoc(doc(asAdmin(env()), 'users/student2')));
    });
  });

  describe(`[mode ${mode}] quiz lifecycle and review`, () => {
    beforeEach(() => seed(env()));

    it('students read published quizzes only', async () => {
      const db = asStudent(env());
      await assertSucceeds(getDoc(doc(db, 'quizzes/qzPub')));
      await assertFails(getDoc(doc(db, 'quizzes/qzDraft')));
    });
    it('admin creates drafts only, as themselves', async () => {
      const db = asAdmin(env());
      await assertSucceeds(setDoc(doc(db, 'quizzes/new1'), newQuiz('admin1')));
      await assertFails(setDoc(doc(db, 'quizzes/new2'), newQuiz('admin1', { status: 'published' })));
      await assertFails(setDoc(doc(db, 'quizzes/new3'), newQuiz('admin2')));
    });
    it('students cannot modify quizzes', async () => {
      await assertFails(updateDoc(doc(asStudent(env()), 'quizzes/qzDraft'), { status: 'published', updatedAt: serverTimestamp() }));
    });
    it('draft -> review -> publish needs a DIFFERENT admin', async () => {
      const a1 = asAdmin(env(), 'admin1');
      const a2 = asAdmin(env(), 'admin2');
      await assertSucceeds(updateDoc(doc(a1, 'quizzes/qzDraft'), { status: 'in_review', lastEditedBy: 'admin1', updatedAt: serverTimestamp() }));
      const publish = (uid) => ({ status: 'published', reviewedBy: uid, reviewedAt: serverTimestamp(), publishedAt: serverTimestamp(), updatedAt: serverTimestamp() });
      await assertFails(updateDoc(doc(a1, 'quizzes/qzDraft'), publish('admin1')));
      await assertFails(updateDoc(doc(a2, 'quizzes/qzDraft'), publish('admin1')));
      await assertSucceeds(updateDoc(doc(a2, 'quizzes/qzDraft'), publish('admin2')));
      await assertSucceeds(getDoc(doc(asStudent(env()), 'quizzes/qzDraft')));
    });
    it('same admin may publish only if config explicitly allows it', async () => {
      await env().withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'config/review'), { requireDifferentReviewer: false }));
      await assertSucceeds(updateDoc(doc(asAdmin(env(), 'admin1'), 'quizzes/qzReview'), {
        status: 'published', reviewedBy: 'admin1', reviewedAt: serverTimestamp(), publishedAt: serverTimestamp(), updatedAt: serverTimestamp(),
      }));
    });
    it('cannot jump from draft straight to published', async () => {
      await assertFails(updateDoc(doc(asAdmin(env(), 'admin2'), 'quizzes/qzDraft'), {
        status: 'published', reviewedBy: 'admin2', reviewedAt: serverTimestamp(), publishedAt: serverTimestamp(), updatedAt: serverTimestamp(),
      }));
    });
    it('content of a published quiz cannot be edited', async () => {
      await assertFails(updateDoc(doc(asAdmin(env()), 'quizzes/qzPub'), { title: loc('Changed'), updatedAt: serverTimestamp() }));
    });
    it('unpublish works; republishing needs draft + review again', async () => {
      const db = asAdmin(env(), 'admin2');
      await assertSucceeds(updateDoc(doc(db, 'quizzes/qzPub'), { status: 'unpublished', updatedAt: serverTimestamp() }));
      await assertFails(updateDoc(doc(db, 'quizzes/qzPub'), { status: 'published', reviewedBy: 'admin2', reviewedAt: serverTimestamp(), publishedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
      await assertSucceeds(updateDoc(doc(db, 'quizzes/qzPub'), { status: 'draft', lastEditedBy: 'admin2', reviewedBy: null, reviewedAt: null, publishedAt: null, updatedAt: serverTimestamp() }));
      await assertFails(getDoc(doc(asStudent(env()), 'quizzes/qzPub')));
    });
    it('published quizzes cannot be deleted, drafts can', async () => {
      const db = asAdmin(env());
      await assertFails(deleteDoc(doc(db, 'quizzes/qzPub')));
      await assertSucceeds(deleteDoc(doc(db, 'quizzes/qzDraft')));
    });
  });

  describe(`[mode ${mode}] questions and answer keys`, () => {
    beforeEach(() => seed(env()));

    it('admin edits questions only while the quiz is a draft', async () => {
      const db = asAdmin(env());
      await assertSucceeds(setDoc(doc(db, 'quizzes/qzDraft/questions/q9'), validQuestion()));
      await assertFails(setDoc(doc(db, 'quizzes/qzPub/questions/q9'), validQuestion()));
      await assertFails(setDoc(doc(db, 'quizzes/qzReview/questions/q9'), validQuestion()));
    });
    it('questions need 4 options and English text', async () => {
      const db = asAdmin(env());
      const bad3 = validQuestion({ translations: { en: { text: 'Q?', options: ['a', 'b', 'c'] } } });
      const noEn = validQuestion({ translations: { hi: { text: 'प्र?', options: ['a', 'b', 'c', 'd'] } } });
      await assertFails(setDoc(doc(db, 'quizzes/qzDraft/questions/q9'), bad3));
      await assertFails(setDoc(doc(db, 'quizzes/qzDraft/questions/q9'), noEn));
    });
    it('students read questions of published quizzes only', async () => {
      const db = asStudent(env());
      await assertSucceeds(getDocs(collection(db, 'quizzes/qzPub/questions')));
      await assertFails(getDocs(collection(db, 'quizzes/qzDraft/questions')));
    });
    it('students cannot write questions', async () => {
      await assertFails(setDoc(doc(asStudent(env()), 'quizzes/qzDraft/questions/q9'), validQuestion({ updatedBy: 'student1' })));
    });
    it('students cannot read answer keys before completing; admins can', async () => {
      await assertFails(getDoc(doc(asStudent(env()), 'quizzes/qzPub/answerKeys/q1')));
      await assertSucceeds(getDoc(doc(asAdmin(env()), 'quizzes/qzPub/answerKeys/q1')));
    });
    it('after completion only that student can read the keys', async () => {
      await env().withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/student1/completed/qzPub'), { attemptId: 'a1', completedAt: Timestamp.now() }));
      await assertSucceeds(getDoc(doc(asStudent(env(), 'student1'), 'quizzes/qzPub/answerKeys/q1')));
      await assertFails(getDoc(doc(asStudent(env(), 'student2'), 'quizzes/qzPub/answerKeys/q1')));
      await assertFails(getDoc(doc(asStudent(env(), 'student1'), 'quizzes/qzDraft/answerKeys/q1')));
    });
    it('answer keys need an in-range index and an English explanation', async () => {
      const db = asAdmin(env());
      await assertSucceeds(setDoc(doc(db, 'quizzes/qzDraft/answerKeys/q9'), validKey()));
      await assertFails(setDoc(doc(db, 'quizzes/qzDraft/answerKeys/q9'), validKey({ correctIndex: 4 })));
      await assertFails(setDoc(doc(db, 'quizzes/qzDraft/answerKeys/q9'), validKey({ explanations: { hi: 'सिर्फ हिंदी' } })));
      await assertFails(setDoc(doc(db, 'quizzes/qzPub/answerKeys/q9'), validKey()));
    });
  });

  describe(`[mode ${mode}] config`, () => {
    beforeEach(() => seed(env()));
    it('config is readable by admins, never writable by clients', async () => {
      await assertFails(getDoc(doc(asStudent(env()), 'config/review')));
      await assertSucceeds(getDoc(doc(asAdmin(env()), 'config/review')));
      await assertFails(setDoc(doc(asAdmin(env()), 'config/review'), { requireDifferentReviewer: false }));
    });
  });
}
