import 'package:flutter_test/flutter_test.dart';
import 'package:rankset_core/rankset_core.dart';

void main() {
  group('LocalizedText', () {
    test('resolves requested language, falls back to English, then anything',
        () {
      final t = LocalizedText.fromMap({'en': 'Hello', 'hi': 'नमस्ते'});
      expect(t.resolve('hi'), 'नमस्ते');
      expect(t.resolve('ta'), 'Hello');
      expect(LocalizedText.fromMap({'hi': 'x'}).resolve('en'), 'x');
      expect(LocalizedText.fromMap(null).resolve('en'), '');
    });
  });

  group('Quiz and Question parsing', () {
    test('quiz picks a supported language', () {
      final q = Quiz.fromMap('z1', {
        'title': {'en': 'T'},
        'languages': ['en'],
        'questionIds': ['a', 'b'],
        'status': 'published',
      });
      expect(q.questionCount, 2);
      expect(q.languageFor('hi'), 'en');
      expect(q.languageFor('en'), 'en');
    });

    test(
        'question keeps one stable id across translations and has no answer data',
        () {
      final q = Question.fromMap('q1', {
        'order': 0,
        'translations': {
          'en': {
            'text': 'Q?',
            'options': ['a', 'b', 'c', 'd']
          },
          'hi': {
            'text': 'प्र?',
            'options': ['अ', 'ब', 'स', 'द']
          },
        },
      });
      expect(q.id, 'q1');
      expect(q.inLanguage('hi').options.length, 4);
      expect(q.inLanguage('ta').text, 'Q?');
    });
  });

  group('ScoreCalculator', () {
    final keys = {
      'q1': AnswerKey(
          questionId: 'q1',
          correctIndex: 1,
          explanations: const LocalizedText({'en': 'E1', 'hi': 'ह1'})),
      'q2': AnswerKey(
          questionId: 'q2',
          correctIndex: 2,
          explanations: const LocalizedText({'en': 'E2'})),
      'q3': AnswerKey(
          questionId: 'q3',
          correctIndex: 0,
          explanations: const LocalizedText({'en': 'E3'})),
    };

    test('counts correct, wrong and unanswered in quiz order', () {
      final r = ScoreCalculator.score(
        attemptId: 'a1',
        quizId: 'z1',
        questionIds: ['q1', 'q2', 'q3'],
        responses: {'q1': 1, 'q2': 0},
        keys: keys,
        language: 'hi',
      );
      expect([r.score, r.total, r.correct, r.wrong, r.unanswered],
          [1, 3, 1, 1, 1]);
      expect(r.questions.map((e) => e.questionId), ['q1', 'q2', 'q3']);
      expect(r.questions[0].explanation, 'ह1');
      expect(r.questions[1].explanation, 'E2');
      expect(r.questions[2].selectedIndex, isNull);
    });

    test('throws when an answer key is missing instead of scoring zero', () {
      expect(
        () => ScoreCalculator.score(
          attemptId: 'a',
          quizId: 'z',
          questionIds: ['q1', 'q9'],
          responses: {},
          keys: keys,
          language: 'en',
        ),
        throwsStateError,
      );
    });

    test('stars thresholds', () {
      AttemptResult r(int c, int t) => AttemptResult(
          attemptId: 'a',
          quizId: 'z',
          score: c,
          total: t,
          correct: c,
          wrong: t - c,
          unanswered: 0,
          questions: const []);
      expect(r(9, 10).stars, 3);
      expect(r(7, 10).stars, 2);
      expect(r(5, 10).stars, 1);
      expect(r(4, 10).stars, 0);
    });
  });

  test('AttemptResult parses the Cloud Function response', () {
    final r = AttemptResult.fromCallable({
      'attemptId': 'u_abc',
      'quizId': 'z1',
      'score': 1,
      'total': 2,
      'correct': 1,
      'wrong': 0,
      'unanswered': 1,
      'results': [
        {
          'questionId': 'q1',
          'selectedIndex': 1,
          'correctIndex': 1,
          'isCorrect': true,
          'explanation': 'E'
        },
        {
          'questionId': 'q2',
          'selectedIndex': null,
          'correctIndex': 2,
          'isCorrect': false,
          'explanation': 'F'
        },
      ],
    });
    expect(r.questions[1].selectedIndex, isNull);
    expect(r.questions[0].isCorrect, isTrue);
  });
}
