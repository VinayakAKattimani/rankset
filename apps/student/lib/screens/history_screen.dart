import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final pal = Palette.of(context);
    return Column(
      children: [
        const IndigoHeader(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('History',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        Expanded(
          child: AsyncView<List<AttemptSummary>>(
            load: () =>
                services.attempts.history(services.auth.currentUser!.uid),
            reloadOn: services.attemptsChanged,
            builder: (context, items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text('You have not completed any quizzes yet.',
                        style: TextStyle(color: pal.muted)),
                  ),
                );
              }
              return LangBuilder(
                builder: (context, lang) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      AttemptTile(summary: items[i], language: lang),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AttemptTile extends StatelessWidget {
  const AttemptTile({super.key, required this.summary, required this.language});
  final AttemptSummary summary;
  final String language;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final pct =
        summary.total == 0 ? 0 : (summary.score * 100 / summary.total).round();
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => HistoryDetailScreen(summary: summary))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.quizTitle.resolve(language),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(formatDate(summary.submittedAt),
                    style: TextStyle(fontSize: 12, color: pal.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${summary.score}/${summary.total}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.saffron)),
              Text('$pct%', style: TextStyle(fontSize: 12, color: pal.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail {
  const _Detail(this.quiz, this.questions, this.result);
  final Quiz quiz;
  final List<Question> questions;
  final AttemptResult result;
}

/// Reopens an earlier attempt. The quiz must still be published to be readable.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.summary});
  final AttemptSummary summary;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<_Detail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Detail> _load() async {
    final s = ServicesScope.of(context);
    final quiz = await s.quizzes.quiz(widget.summary.quizId);
    final questions = await s.quizzes.questions(widget.summary.quizId);
    final result = await s.attempts.loadResult(widget.summary.id);
    return _Detail(quiz, questions, result);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Detail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: rankAppBar(context, 'Result'),
            body: const Center(
                child: CircularProgressIndicator(color: AppColors.indigo)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: rankAppBar(context, 'Result'),
            body: ErrorRetry(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            ),
          );
        }
        final d = snapshot.data!;
        return ResultScreen(
            quiz: d.quiz,
            questions: d.questions,
            result: d.result,
            language: widget.summary.language);
      },
    );
  }
}
