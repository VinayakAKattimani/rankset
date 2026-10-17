import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rankset_core/rankset_core.dart';
import 'package:rankset_student/screens/premium_screen.dart';
import 'package:rankset_student/screens/ranking_screen.dart';
import 'package:rankset_student/screens/result_screen.dart';
import 'package:rankset_student/services/study_stats.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light('en'),
      home: home,
    );

void main() {
  test('streak metrics use distinct persisted completion dates', () {
    final attempts = [
      _attempt('a', DateTime(2026, 10, 15, 9)),
      _attempt('b', DateTime(2026, 10, 15, 18)),
      _attempt('c', DateTime(2026, 10, 16, 9)),
      _attempt('d', DateTime(2026, 10, 17, 9)),
    ];
    final stats =
        StudyStats.fromAttempts(attempts, now: DateTime(2026, 10, 17));

    expect(stats.currentStreak, 3);
    expect(stats.bestStreak, 3);
    expect(stats.completedDays, hasLength(3));
    expect(stats.completedOn(DateTime(2026, 10, 15)), isTrue);
  });

  test('empty attempt history has no streak', () {
    final stats =
        StudyStats.fromAttempts(const [], now: DateTime(2026, 10, 17));

    expect(stats.currentStreak, 0);
    expect(stats.bestStreak, 0);
    expect(stats.completedDays, isEmpty);
  });

  testWidgets('Premium preview shows reference benefits and sample pricing',
      (tester) async {
    await tester.pumpWidget(_app(const PremiumScreen()));

    expect(find.text('Go Premium'), findsOneWidget);
    expect(find.text('Notes for every topic'), findsOneWidget);
    expect(find.text('Unlimited MCQ practice'), findsOneWidget);
    expect(find.text('Rs 49'), findsOneWidget);
    expect(find.text('Rs 399'), findsOneWidget);
    expect(find.text('Preview only · plans and prices are examples'),
        findsOneWidget);
  });

  testWidgets('Premium continue action is clearly nonfunctional preview',
      (tester) async {
    await tester.pumpWidget(_app(const PremiumScreen()));
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Preview only. Purchases are not available.'),
        findsOneWidget);
  });

  testWidgets('Premium close button returns to the previous screen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const PremiumScreen(),
            )),
            child: const Text('Open premium'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open premium'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Open premium'), findsOneWidget);
  });

  testWidgets('Ranking preview labels sample data and shows reference rows',
      (tester) async {
    await tester.pumpWidget(_app(const RankingScreen()));

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('LOCAL DEMO · sample rankings, not real students'),
        findsOneWidget);
    expect(find.text('Rahul_K'), findsOneWidget);
    expect(find.text('98 pts'), findsOneWidget);
    expect(find.text('You (Demo)'), findsOneWidget);
    expect(find.text('78 pts'), findsOneWidget);
  });

  testWidgets('Ranking period tabs are interactive', (tester) async {
    await tester.pumpWidget(_app(const RankingScreen()));
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();

    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);
  });

  testWidgets('Results points state is honest and opens shared RankingScreen',
      (tester) async {
    final quiz = Quiz(
      id: 'sample',
      examId: 'exam',
      subjectId: 'subject',
      topicId: 'topic',
      title: const LocalizedText({'en': 'Sample quiz'}),
      languages: const ['en'],
      questionIds: const [],
      status: 'published',
    );
    const result = AttemptResult(
      attemptId: 'attempt',
      quizId: 'sample',
      score: 0,
      total: 0,
      correct: 0,
      wrong: 0,
      unanswered: 0,
      questions: [],
    );
    await tester.pumpWidget(_app(ResultScreen(
      quiz: quiz,
      questions: const [],
      result: result,
      language: 'en',
    )));

    expect(find.text('Points earned'), findsOneWidget);
    expect(find.text('Points are not calculated for this attempt.'),
        findsOneWidget);
    await tester.tap(find.text('View leaderboard'));
    await tester.pumpAndSettle();

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('LOCAL DEMO · sample rankings, not real students'),
        findsOneWidget);
  });
}

AttemptSummary _attempt(String id, DateTime date) => AttemptSummary(
      id: id,
      quizId: 'quiz',
      quizTitle: const LocalizedText({'en': 'Sample quiz'}),
      language: 'en',
      score: 1,
      total: 1,
      submittedAt: date,
      scoreSource: 'client',
    );
