import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../services/study_stats.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'practice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPractice});

  final ValueChanged<PracticeMode> onOpenPractice;

  Future<List<AttemptSummary>> _load(Services services) =>
      services.attempts.history(services.auth.currentUser!.uid, limit: 50);

  Future<void> _openPracticeChoice(BuildContext context) async {
    final mode = await showDialog<PracticeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose where to practise'),
        content: const Text('Browse by exam or by subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, PracticeMode.exams),
            child: const Text('Exams'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, PracticeMode.subjects),
            child: const Text('Subjects'),
          ),
        ],
      ),
    );
    if (mode != null) onOpenPractice(mode);
  }

  Future<void> _dailyQuizUnavailable(BuildContext context) async {
    final goToPractice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily quiz unavailable'),
        content: const Text(
            'No verified current-affairs quiz is configured in this demo. You can choose an available sample quiz in Practice.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Practice')),
        ],
      ),
    );
    if (goToPractice == true) onOpenPractice(PracticeMode.exams);
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final pal = Palette.of(context);
    final user = services.auth.currentUser;
    final displayName = user?.displayName?.trim();
    final name =
        displayName != null && displayName.isNotEmpty ? displayName : 'there';

    return Column(
      children: [
        IndigoHeader(
          bottomPadding: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, $name',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Ready for today’s quiz?',
                  style: TextStyle(fontSize: 13, color: Color(0xFFC9C8F0))),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<AttemptSummary>>(
            load: () => _load(services),
            reloadOn: services.attemptsChanged,
            builder: (context, attempts) {
              final stats = StudyStats.fromAttempts(attempts);
              final recent = [...attempts]..sort((a, b) =>
                  (b.submittedAt ?? DateTime(0))
                      .compareTo(a.submittedAt ?? DateTime(0)));
              return LangBuilder(
                builder: (context, lang) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StreakCard(stats: stats),
                    const SizedBox(height: 14),
                    _TodayQuizCard(
                        onStart: () => _dailyQuizUnavailable(context)),
                    const SizedBox(height: 14),
                    _ChoosePracticeCard(
                        onStart: () => _openPracticeChoice(context)),
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text('Recent results',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      for (final attempt in recent.take(3)) ...[
                        AttemptTile(summary: attempt, language: lang),
                        const SizedBox(height: 10),
                      ],
                    ] else ...[
                      const SizedBox(height: 18),
                      Text('Complete a quiz to see your recent results here.',
                          style: TextStyle(color: pal.muted)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});
  final StudyStats stats;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final days = stats.weekDays();
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                    color: AppColors.saffron, shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department,
                    color: Colors.white, size: 29),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${stats.currentStreak} Day Streak',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                        stats.currentStreak > 0
                            ? 'Keep it going!'
                            : 'Complete a quiz to start a streak.',
                        style: TextStyle(fontSize: 11, color: pal.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          final isToday =
                              DateUtils.isSameDay(days[i], DateTime.now());
                          final completed = stats.completedOn(days[i]);
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday
                                  ? pal.card
                                  : (completed
                                      ? AppColors.saffron
                                      : Colors.transparent),
                              border: Border.all(
                                color: isToday
                                    ? AppColors.saffron
                                    : (completed
                                        ? AppColors.saffron
                                        : pal.border),
                                width: isToday ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isToday && completed)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                        color: AppColors.saffron,
                                        shape: BoxShape.circle),
                                  ),
                                Text(_weekdays[i],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: completed && !isToday
                                          ? Colors.white
                                          : (isToday && completed
                                              ? Colors.white
                                              : (isToday
                                                  ? AppColors.saffron
                                                  : pal.muted)),
                                    )),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayQuizCard extends StatelessWidget {
  const _TodayQuizCard({required this.onStart});
  final VoidCallback onStart;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final date = '${today.day} ${_months[today.month - 1]}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: 18,
            child: Icon(Icons.circle,
                size: 90, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TODAY’S QUIZ",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.saffron)),
              const SizedBox(height: 6),
              Text('Current-affairs date · $date',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text('Planned format · 10 Questions · 5 mins',
                  style: TextStyle(fontSize: 11, color: Color(0xFFC9C8F0))),
              const SizedBox(height: 4),
              const Text('No verified daily quiz is configured in this demo.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC9C8F0))),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: AppColors.text,
                  minimumSize: const Size(132, 44),
                ),
                child: const Text('Start Quiz',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoosePracticeCard extends StatelessWidget {
  const _ChoosePracticeCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: pal.tint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppColors.indigo),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Choose a subject or exam',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.indigo,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }
}
