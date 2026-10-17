import 'models/attempt.dart';
import 'models/quiz.dart';

/// Scoring on the device. Used (a) to rebuild a result when reviewing history, and (b) in scoring
/// mode B where the phone computes the score. In mode A the server's result is the source of truth.
class ScoreCalculator {
  const ScoreCalculator._();

  static AttemptResult score({
    required String attemptId,
    required String quizId,
    required List<String> questionIds,
    required Map<String, int> responses,
    required Map<String, AnswerKey> keys,
    required String language,
  }) {
    var correct = 0;
    var wrong = 0;
    var unanswered = 0;
    final results = <QuestionResult>[];
    for (final qid in questionIds) {
      final key = keys[qid];
      if (key == null) {
        throw StateError('Missing answer key for question $qid');
      }
      final selected = responses[qid];
      final isCorrect = selected != null && selected == key.correctIndex;
      if (selected == null) {
        unanswered++;
      } else if (isCorrect) {
        correct++;
      } else {
        wrong++;
      }
      results.add(QuestionResult(
        questionId: qid,
        selectedIndex: selected,
        correctIndex: key.correctIndex,
        isCorrect: isCorrect,
        explanation: key.explanations.resolve(language),
      ));
    }
    return AttemptResult(
      attemptId: attemptId,
      quizId: quizId,
      score: correct,
      total: questionIds.length,
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      questions: results,
    );
  }
}
