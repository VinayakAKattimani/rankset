import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../widgets/common.dart';
import '../widgets/option_tile.dart';
import 'ranking_screen.dart';

/// Score, counts and a review of every question with the correct answer and explanation.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.quiz,
    required this.questions,
    required this.result,
    required this.language,
  });

  final Quiz quiz;
  final List<Question> questions;
  final AttemptResult result;
  final String language;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final byId = {for (final q in questions) q.id: q};
    final percent = result.total == 0 ? 0.0 : result.correct / result.total;

    final scaffold = Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.indigo,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                child: Column(
                  children: [
                    const Text('Quiz complete!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(quiz.title.resolve(language),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFC9C8F0))),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: percent,
                              strokeWidth: 9,
                              color: AppColors.saffron,
                              backgroundColor: AppColors.indigoSoft,
                            ),
                          ),
                          Text('${result.correct}/${result.total}',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(Icons.star_rounded,
                              size: 34,
                              color: i < result.stars
                                  ? AppColors.saffron
                                  : AppColors.indigoSoft),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Stat(
                        label: 'Correct',
                        value: result.correct,
                        color: AppColors.green),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Wrong',
                        value: result.wrong,
                        color: AppColors.red),
                    const SizedBox(width: 10),
                    _Stat(
                        label: 'Skipped',
                        value: result.unanswered,
                        color: pal.muted),
                  ],
                ),
                const SizedBox(height: 14),
                _PointsEarnedCard(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const RankingScreen()),
                  ),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      minimumSize: const Size.fromHeight(50)),
                  child: const Text('View leaderboard'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Back to home'),
                ),
                const SizedBox(height: 22),
                const Text('Review your answers',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (var i = 0; i < result.questions.length; i++) ...[
                  if (byId[result.questions[i].questionId] != null)
                    _ReviewCard(
                      number: i + 1,
                      question: byId[result.questions[i].questionId]!,
                      result: result.questions[i],
                      language: language,
                    ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return withLanguageFont(context, language, scaffold);
  }
}

class _PointsEarnedCard extends StatelessWidget {
  const _PointsEarnedCard();

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return AppCard(
      color: pal.tint,
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.saffron, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points earned',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Points are not calculated for this attempt.',
                    style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          Text('—',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: pal.muted)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: pal.muted)),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(
      {required this.number,
      required this.question,
      required this.result,
      required this.language});
  final int number;
  final Question question;
  final QuestionResult result;
  final String language;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final tr = question.inLanguage(language);
    final String status = result.selectedIndex == null
        ? 'Skipped'
        : (result.isCorrect ? 'Correct' : 'Wrong');
    final Color statusColor = result.selectedIndex == null
        ? pal.muted
        : (result.isCorrect ? AppColors.green : AppColors.red);

    OptionState stateFor(int i) {
      if (i == result.correctIndex) return OptionState.correct;
      if (i == result.selectedIndex) return OptionState.wrong;
      return OptionState.normal;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q$number',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.saffron)),
              const Spacer(),
              Text(status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(tr.text,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 12),
          for (var i = 0; i < tr.options.length; i++) ...[
            OptionTile(
                letter: 'ABCD'[i], text: tr.options[i], state: stateFor(i)),
            const SizedBox(height: 8),
          ],
          if (result.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: pal.tint, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPLANATION',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pal.dark ? Colors.white : AppColors.indigo)),
                  const SizedBox(height: 4),
                  Text(result.explanation,
                      style: const TextStyle(fontSize: 14, height: 1.45)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
