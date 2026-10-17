import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { Timestamp, serverTimestamp, doc, setDoc } from 'firebase/firestore';
import { buildRules } from '../../scripts/build-rules.js';

export { assertFails, assertSucceeds, serverTimestamp, Timestamp };

export function makeEnv(mode) {
  // Uses the exact rules the build script generates. FIRESTORE_EMULATOR_HOST is set by `firebase emulators:exec`.
  return initializeTestEnvironment({ projectId: 'demo-rankset', firestore: { rules: buildRules(mode) } });
}

export const asAdmin = (env, uid = 'admin1') =>
  env.authenticatedContext(uid, { admin: true, email_verified: true, email: `${uid}@rankset.test` }).firestore();
export const asStudent = (env, uid = 'student1') =>
  env.authenticatedContext(uid, { email_verified: true, email: `${uid}@rankset.test` }).firestore();
export const asUnverifiedAdmin = (env) =>
  env.authenticatedContext('admin9', { admin: true, email_verified: false, email: 'admin9@rankset.test' }).firestore();
export const asAnon = (env) => env.unauthenticatedContext().firestore();

export const loc = (en, hi) => (hi ? { en, hi } : { en });

export const validQuestion = (overrides = {}) => ({
  order: 0,
  translations: {
    en: { text: 'Question?', options: ['a', 'b', 'c', 'd'] },
    hi: { text: 'प्रश्न?', options: ['अ', 'ब', 'स', 'द'] },
  },
  updatedAt: serverTimestamp(),
  updatedBy: 'admin1',
  ...overrides,
});

export const validKey = (overrides = {}) => ({
  correctIndex: 1,
  explanations: loc('Because.', 'क्योंकि।'),
  updatedAt: serverTimestamp(),
  updatedBy: 'admin1',
  ...overrides,
});

export const newQuiz = (by = 'admin1', overrides = {}) => ({
  examId: 'exam1', subjectId: 'subj1', topicId: 'topic1',
  title: loc('Quiz', 'क्विज़'), languages: ['en', 'hi'], status: 'draft',
  questionIds: ['q1', 'q2'], questionCount: 2,
  createdBy: by, lastEditedBy: by, reviewedBy: null, reviewedAt: null, publishedAt: null,
  updatedAt: serverTimestamp(),
  ...overrides,
});

// Writes baseline data with rules disabled.
export async function seed(env) {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const now = Timestamp.now();
    const stamp = { updatedAt: now, updatedBy: 'admin1' };
    await setDoc(doc(db, 'categories/cat1'), { name: loc('SSC', 'एसएससी'), order: 1, isPublished: true, ...stamp });
    await setDoc(doc(db, 'categories/catHidden'), { name: loc('Hidden'), order: 2, isPublished: false, ...stamp });
    await setDoc(doc(db, 'exams/exam1'), { categoryId: 'cat1', name: loc('CGL'), order: 1, isPublished: true, ...stamp });
    await setDoc(doc(db, 'subjects/subj1'), { examId: 'exam1', name: loc('GA'), order: 1, isPublished: true, ...stamp });
    await setDoc(doc(db, 'topics/topic1'), { examId: 'exam1', subjectId: 'subj1', name: loc('Basics'), order: 1, isPublished: true, ...stamp });
    await setDoc(doc(db, 'config/review'), { requireDifferentReviewer: true });

    const quiz = (status, extra = {}) => ({
      examId: 'exam1', subjectId: 'subj1', topicId: 'topic1',
      title: loc('Quiz', 'क्विज़'), languages: ['en', 'hi'], status,
      questionIds: ['q1', 'q2'], questionCount: 2,
      createdBy: 'admin1', lastEditedBy: 'admin1', reviewedBy: null, reviewedAt: null, publishedAt: null, updatedAt: now,
      ...extra,
    });
    await setDoc(doc(db, 'quizzes/qzPub'), quiz('published', { reviewedBy: 'admin2', reviewedAt: now, publishedAt: now }));
    await setDoc(doc(db, 'quizzes/qzDraft'), quiz('draft'));
    await setDoc(doc(db, 'quizzes/qzReview'), quiz('in_review'));
    for (const qz of ['qzPub', 'qzDraft', 'qzReview']) {
      for (const [i, id] of ['q1', 'q2'].entries()) {
        await setDoc(doc(db, `quizzes/${qz}/questions/${id}`), {
          order: i,
          translations: { en: { text: 'Question?', options: ['a', 'b', 'c', 'd'] } },
          updatedAt: now, updatedBy: 'admin1',
        });
        await setDoc(doc(db, `quizzes/${qz}/answerKeys/${id}`), { correctIndex: 1, explanations: loc('Because.'), updatedAt: now, updatedBy: 'admin1' });
      }
    }
  });
}
