// Seeds the LOCAL EMULATORS with demo users and one published quiz. Refuses to run against production.
//   Terminal 1: npm run emulators
//   Terminal 2: npm run seed:emulator
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { initAdmin } from './lib/admin-init.js';
import { IDS, catalog, questions, quizTitle, demoUsers } from './demo-data.js';

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  console.log('Using default emulator hosts 127.0.0.1:8080 and :9099');
}
initAdmin('demo-rankset');
const db = getFirestore();
const auth = getAuth();
const now = FieldValue.serverTimestamp();

for (const u of demoUsers) {
  try { await auth.getUser(u.uid); } catch {
    await auth.createUser({ uid: u.uid, email: u.email, password: u.password, emailVerified: true, displayName: u.uid });
  }
  await auth.setCustomUserClaims(u.uid, u.admin ? { admin: true } : {});
}

const stamp = (o) => ({ ...o, updatedAt: now, updatedBy: 'admin1' });
for (const c of catalog.categories) await db.doc(`categories/${c.id}`).set(stamp({ name: c.name, order: c.order, isPublished: c.isPublished }));
for (const e of catalog.exams) await db.doc(`exams/${e.id}`).set(stamp({ categoryId: e.categoryId, name: e.name, order: e.order, isPublished: e.isPublished }));
for (const s of catalog.subjects) await db.doc(`subjects/${s.id}`).set(stamp({ examId: s.examId, name: s.name, order: s.order, isPublished: s.isPublished }));
for (const t of catalog.topics) await db.doc(`topics/${t.id}`).set(stamp({ examId: t.examId, subjectId: t.subjectId, name: t.name, order: t.order, isPublished: t.isPublished }));

await db.doc(`quizzes/${IDS.quiz}`).set({
  examId: IDS.exam, subjectId: IDS.subject, topicId: IDS.topic,
  title: quizTitle, languages: ['en', 'hi'], status: 'published',
  questionIds: questions.map((q) => q.id), questionCount: questions.length,
  createdBy: 'admin1', lastEditedBy: 'admin1', reviewedBy: 'admin2', reviewedAt: now, publishedAt: now, updatedAt: now,
});
for (const q of questions) {
  await db.doc(`quizzes/${IDS.quiz}/questions/${q.id}`).set(stamp({ order: q.order, translations: { en: q.en, hi: q.hi } }));
  await db.doc(`quizzes/${IDS.quiz}/answerKeys/${q.id}`).set(stamp({ correctIndex: q.correctIndex, explanations: q.explanation }));
}
await db.doc('config/review').set({ requireDifferentReviewer: true });

console.log('Seeded. Demo logins (password Passw0rd!demo): admin1@rankset.test, admin2@rankset.test, student@rankset.test');
