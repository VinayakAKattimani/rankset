// Pure scoring logic. No Firebase imports, fully unit tested.

export class AppError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code; // maps to HttpsError codes: 'unauthenticated', 'invalid-argument', 'not-found', 'failed-precondition', ...
  }
}

export const SUPPORTED_LANGUAGES = ['en', 'hi', 'bn', 'ta', 'te', 'mr', 'gu', 'kn', 'ml', 'pa'];

export function pickText(localized, language) {
  if (!localized || typeof localized !== 'object') return '';
  return localized[language] ?? localized.en ?? Object.values(localized)[0] ?? '';
}

// responses: { questionId: optionIndex } containing ONLY answered questions.
export function validateResponses(responses, questionIds) {
  if (responses === null || typeof responses !== 'object' || Array.isArray(responses)) {
    throw new AppError('invalid-argument', 'responses must be an object');
  }
  const allowed = new Set(questionIds);
  for (const [qid, value] of Object.entries(responses)) {
    if (!allowed.has(qid)) throw new AppError('invalid-argument', `Unknown question: ${qid}`);
    if (!Number.isInteger(value) || value < 0 || value > 3) {
      throw new AppError('invalid-argument', `Invalid answer for question ${qid}`);
    }
  }
}

// keysById: { questionId: { correctIndex, explanations } }. Returns counts and per-question detail in quiz order.
export function scoreAttempt({ questionIds, keysById, responses, language }) {
  let correct = 0;
  let wrong = 0;
  let unanswered = 0;
  const results = questionIds.map((questionId) => {
    const key = keysById[questionId];
    const selected = Object.prototype.hasOwnProperty.call(responses, questionId) ? responses[questionId] : null;
    const isCorrect = selected !== null && selected === key.correctIndex;
    if (selected === null) unanswered++;
    else if (isCorrect) correct++;
    else wrong++;
    return {
      questionId,
      selectedIndex: selected,
      correctIndex: key.correctIndex,
      isCorrect,
      explanation: pickText(key.explanations, language),
    };
  });
  return { score: correct, total: questionIds.length, correct, wrong, unanswered, results };
}
