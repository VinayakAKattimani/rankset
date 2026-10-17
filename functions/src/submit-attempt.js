// Mode A scoring: called by the callable Cloud Function. Takes injected dependencies so it can be tested
// without Firebase. `db` is a Firestore Admin SDK-like object: doc(path), getAll(...refs), runTransaction(fn).
import { AppError, SUPPORTED_LANGUAGES, pickText, scoreAttempt, validateResponses } from './scoring.js';

const ID_RE = /^[A-Za-z0-9_-]{8,64}$/;

function toResponse(attemptId, quizId, scored) {
  return { attemptId, quizId, ...scored };
}

export async function handleSubmitAttempt({ db, uid, data, now = new Date() }) {
  if (!uid) throw new AppError('unauthenticated', 'Sign in first');
  const { quizId, language, responses, clientAttemptId, startedAtMs } = data ?? {};
  if (typeof quizId !== 'string' || !quizId || quizId.includes('/')) throw new AppError('invalid-argument', 'quizId is required');
  if (typeof language !== 'string' || !SUPPORTED_LANGUAGES.includes(language)) throw new AppError('invalid-argument', 'Unsupported language');
  if (typeof clientAttemptId !== 'string' || !ID_RE.test(clientAttemptId)) throw new AppError('invalid-argument', 'clientAttemptId is invalid');

  const quizSnap = await db.doc(`quizzes/${quizId}`).get();
  if (!quizSnap.exists) throw new AppError('not-found', 'Quiz not found');
  const quiz = quizSnap.data();
  if (quiz.status !== 'published') throw new AppError('failed-precondition', 'Quiz is not available');
  if (!Array.isArray(quiz.languages) || !quiz.languages.includes(language)) throw new AppError('invalid-argument', 'Quiz is not available in this language');

  validateResponses(responses ?? {}, quiz.questionIds);

  const keyRefs = quiz.questionIds.map((id) => db.doc(`quizzes/${quizId}/answerKeys/${id}`));
  const keySnaps = keyRefs.length ? await db.getAll(...keyRefs) : [];
  const keysById = {};
  keySnaps.forEach((snap, i) => {
    if (!snap.exists) throw new AppError('failed-precondition', 'Quiz is missing answer keys');
    keysById[quiz.questionIds[i]] = snap.data();
  });

  const scored = scoreAttempt({ questionIds: quiz.questionIds, keysById, responses: responses ?? {}, language });

  // Idempotent: the same clientAttemptId always maps to the same attempt document.
  const attemptId = `${uid}_${clientAttemptId}`;
  const attemptRef = db.doc(`attempts/${attemptId}`);
  const markerRef = db.doc(`users/${uid}/completed/${quizId}`);

  let startedAt = now;
  if (Number.isFinite(startedAtMs) && startedAtMs <= now.getTime() && now.getTime() - startedAtMs <= 24 * 3600 * 1000) {
    startedAt = new Date(startedAtMs);
  }

  const existing = await db.runTransaction(async (tx) => {
    const snap = await tx.get(attemptRef);
    if (snap.exists) return snap.data();
    tx.create(attemptRef, {
      uid, quizId, quizTitle: quiz.title, examId: quiz.examId, subjectId: quiz.subjectId, topicId: quiz.topicId,
      language, startedAt, submittedAt: now, responses: responses ?? {},
      score: scored.score, total: scored.total, correct: scored.correct, wrong: scored.wrong, unanswered: scored.unanswered,
      scoreSource: 'server',
    });
    tx.set(markerRef, { attemptId, completedAt: now });
    return null;
  });

  if (existing) {
    // Retry of an earlier submit: return the result of the stored answers, not the new payload.
    const again = scoreAttempt({ questionIds: quiz.questionIds, keysById, responses: existing.responses ?? {}, language: existing.language ?? language });
    return toResponse(attemptId, quizId, again);
  }
  return toResponse(attemptId, quizId, scored);
}

export { pickText };
