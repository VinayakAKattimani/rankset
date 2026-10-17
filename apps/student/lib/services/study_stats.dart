import 'package:rankset_core/rankset_core.dart';

/// Streak values derived only from persisted quiz submissions.
class StudyStats {
  const StudyStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedDays,
  });

  final int currentStreak;
  final int bestStreak;
  final Set<DateTime> completedDays;

  factory StudyStats.fromAttempts(List<AttemptSummary> attempts,
      {DateTime? now}) {
    DateTime day(DateTime date) => DateTime.utc(
        date.toLocal().year, date.toLocal().month, date.toLocal().day);

    final days = <DateTime>{
      for (final attempt in attempts)
        if (attempt.submittedAt != null) day(attempt.submittedAt!),
    };
    final sorted = days.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final completed in sorted) {
      run = previous != null && completed.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = completed;
    }

    final today = day(now ?? DateTime.now());
    var anchor = today;
    if (!days.contains(today)) anchor = today.subtract(const Duration(days: 1));
    var current = 0;
    while (days.contains(anchor)) {
      current++;
      anchor = anchor.subtract(const Duration(days: 1));
    }
    return StudyStats(
        currentStreak: current, bestStreak: best, completedDays: days);
  }

  bool completedOn(DateTime date) =>
      completedDays.contains(DateTime.utc(date.year, date.month, date.day));

  List<DateTime> weekDays({DateTime? now}) {
    final today = now ?? DateTime.now();
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - DateTime.monday));
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }
}
