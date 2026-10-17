import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../widgets/common.dart';

/// Local-only rankings that mirror the supplied leaderboard reference.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int _selectedPeriod = 0;

  static const _entries = <({String name, int points})>[
    (name: 'Rahul_K', points: 98),
    (name: 'Sneha.M', points: 96),
    (name: 'quizking', points: 95),
    (name: 'Aman_R', points: 93),
    (name: 'Divya_S', points: 92),
    (name: 'Imran.A', points: 90),
    (name: 'Neha_P', points: 89),
  ];

  static const _periods = ['Today', 'This Week', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      appBar: rankAppBar(context, 'Leaderboard',
          subtitle: 'Daily ranking that gives people a reason to return'),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: pal.bg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: pal.tint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _periods.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedPeriod == i
                                ? AppColors.indigo
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_periods[i],
                              style: TextStyle(
                                color: _selectedPeriod == i
                                    ? Colors.white
                                    : pal.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.saffron.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                  'LOCAL DEMO · sample rankings, not real students',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 92),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return _RankRow(
                    rank: index + 1, name: entry.name, points: entry.points);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.saffron,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('124',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.person, size: 12, color: AppColors.indigo),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You (Demo)',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          Text('Sample rank · not live',
                              style: TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    Text('78 pts',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow(
      {required this.rank, required this.name, required this.points});

  final int rank;
  final String name;
  final int points;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final medal = switch (rank) {
      1 => const Color(0xFFFFB900),
      2 => const Color(0xFFAFB7C5),
      3 => const Color(0xFFCD7F45),
      _ => null,
    };
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: pal.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal == null
                ? Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: pal.muted))
                : CircleAvatar(
                    radius: 10,
                    backgroundColor: medal,
                    child: Text('$rank',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
              radius: 9, backgroundColor: pal.tint, child: const SizedBox()),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Text('$points pts',
              style: TextStyle(
                  fontSize: 10,
                  color: pal.dark ? AppColors.saffron : AppColors.indigo,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
