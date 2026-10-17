import 'localized_text.dart';
import 'quiz.dart';

class QuestionResult {
  const QuestionResult({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final int? selectedIndex; // null = unanswered
  final int correctIndex;
  final bool isCorrect;
  final String explanation;

  factory QuestionResult.fromMap(Map<String, dynamic> m) => QuestionResult(
        questionId: m['questionId'] as String,
        selectedIndex: m['selectedIndex'] is num
            ? (m['selectedIndex'] as num).toInt()
            : null,
        correctIndex: asInt(m['correctIndex']),
        isCorrect: m['isCorrect'] == true,
        explanation: (m['explanation'] as String?) ?? '',
      );
}

class AttemptResult {
  const AttemptResult({
    required this.attemptId,
    required this.quizId,
    required this.score,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.questions,
  });

  final String attemptId;
  final String quizId;
  final int score;
  final int total;
  final int correct;
  final int wrong;
  final int unanswered;
  final List<QuestionResult> questions;

  double get percentage => total == 0 ? 0 : correct * 100 / total;

  /// 1 star from 50%, 2 from 70%, 3 from 90%.
  int get stars => percentage >= 90
      ? 3
      : (percentage >= 70 ? 2 : (percentage >= 50 ? 1 : 0));

  factory AttemptResult.fromCallable(Map<String, dynamic> m) => AttemptResult(
        attemptId: m['attemptId'] as String,
        quizId: m['quizId'] as String,
        score: asInt(m['score']),
        total: asInt(m['total']),
        correct: asInt(m['correct']),
        wrong: asInt(m['wrong']),
        unanswered: asInt(m['unanswered']),
        questions: ((m['results'] as List?) ?? const [])
            .map((e) =>
                QuestionResult.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// One row in the history list. Stored on the attempt so the list needs no extra reads.
class AttemptSummary {
  const AttemptSummary({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.language,
    required this.score,
    required this.total,
    required this.submittedAt,
    required this.scoreSource,
  });

  final String id;
  final String quizId;
  final LocalizedText quizTitle;
  final String language;
  final int score;
  final int total;
  final DateTime? submittedAt;
  final String scoreSource;

  factory AttemptSummary.fromMap(String id, Map<String, dynamic> m) =>
      AttemptSummary(
        id: id,
        quizId: (m['quizId'] as String?) ?? '',
        quizTitle: LocalizedText.fromMap(m['quizTitle']),
        language: (m['language'] as String?) ?? 'en',
        score: asInt(m['score']),
        total: asInt(m['total']),
        submittedAt: asDate(m['submittedAt']),
        scoreSource: (m['scoreSource'] as String?) ?? 'server',
      );
}

class SubmitRequest {
  const SubmitRequest({
    required this.quiz,
    required this.language,
    required this.responses,
    required this.startedAt,
    required this.clientAttemptId,
  });

  final Quiz quiz;
  final String language;

  /// Only answered questions: questionId -> option index (0-3).
  final Map<String, int> responses;
  final DateTime startedAt;

  /// Generated once per quiz session so a retried submit cannot create a duplicate attempt.
  final String clientAttemptId;
}
