import 'localized_text.dart';

class Quiz {
  const Quiz({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.topicId,
    required this.title,
    required this.languages,
    required this.questionIds,
    required this.status,
  });

  final String id;
  final String examId;
  final String subjectId;
  final String topicId;
  final LocalizedText title;
  final List<String> languages;
  final List<String> questionIds;
  final String status;

  int get questionCount => questionIds.length;

  /// The language to actually use: the preferred one if the quiz has it, otherwise English.
  String languageFor(String preferred) =>
      languages.contains(preferred) ? preferred : 'en';

  factory Quiz.fromMap(String id, Map<String, dynamic> m) => Quiz(
        id: id,
        examId: (m['examId'] as String?) ?? '',
        subjectId: (m['subjectId'] as String?) ?? '',
        topicId: (m['topicId'] as String?) ?? '',
        title: LocalizedText.fromMap(m['title']),
        languages: List<String>.from((m['languages'] as List?) ?? const ['en']),
        questionIds: List<String>.from((m['questionIds'] as List?) ?? const []),
        status: (m['status'] as String?) ?? 'draft',
      );
}

class QuestionTranslation {
  const QuestionTranslation({required this.text, required this.options});
  final String text;
  final List<String> options;
}

/// A question has one stable [id] shared by all languages. It never contains the answer.
class Question {
  const Question(
      {required this.id, required this.order, required this.translations});

  final String id;
  final int order;
  final Map<String, QuestionTranslation> translations;

  QuestionTranslation inLanguage(String language) =>
      translations[language] ?? translations['en'] ?? translations.values.first;

  factory Question.fromMap(String id, Map<String, dynamic> m) {
    final out = <String, QuestionTranslation>{};
    final raw = m['translations'];
    if (raw is Map) {
      raw.forEach((lang, value) {
        if (lang is String && value is Map) {
          out[lang] = QuestionTranslation(
            text: (value['text'] as String?) ?? '',
            options: List<String>.from((value['options'] as List?) ?? const []),
          );
        }
      });
    }
    return Question(id: id, order: asInt(m['order']), translations: out);
  }
}

class AnswerKey {
  const AnswerKey(
      {required this.questionId,
      required this.correctIndex,
      required this.explanations});
  final String questionId;
  final int correctIndex;
  final LocalizedText explanations;

  factory AnswerKey.fromMap(String questionId, Map<String, dynamic> m) =>
      AnswerKey(
        questionId: questionId,
        correctIndex: asInt(m['correctIndex']),
        explanations: LocalizedText.fromMap(m['explanations']),
      );
}
