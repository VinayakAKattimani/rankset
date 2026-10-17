import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../widgets/common.dart';
import '../widgets/option_tile.dart';
import 'result_screen.dart';

/// Loads the questions (never containing answers) and then shows the quiz player.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quiz});
  final Quiz quiz;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<Question>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Question>> _load() async {
    final questions =
        await ServicesScope.of(context).quizzes.questions(widget.quiz.id);
    final ids = widget.quiz.questionIds;
    final byId = {for (final q in questions) q.id: q};
    // Follow the quiz's own question order, and refuse to start a quiz that is incomplete.
    final ordered = [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];
    if (ordered.isEmpty || ordered.length != ids.length) {
      throw StateError('This quiz is not ready yet. Please try another one.');
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: rankAppBar(context, 'Loading quiz'),
            body: const Center(
                child: CircularProgressIndicator(color: AppColors.indigo)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: rankAppBar(context, 'Quiz'),
            body: ErrorRetry(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            ),
          );
        }
        return QuizPlayer(quiz: widget.quiz, questions: snapshot.data!);
      },
    );
  }
}

class QuizPlayer extends StatefulWidget {
  const QuizPlayer({super.key, required this.quiz, required this.questions});
  final Quiz quiz;
  final List<Question> questions;

  @override
  State<QuizPlayer> createState() => _QuizPlayerState();
}

class _QuizPlayerState extends State<QuizPlayer> {
  late String _language;
  late final DateTime _startedAt;
  late final String _clientAttemptId;
  final Map<String, int> _responses = {};
  int _index = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _clientAttemptId = _randomId();
    _language =
        widget.quiz.languageFor(ServicesScope.of(context).language.language);
  }

  static String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }

  int get _total => widget.questions.length;
  Question get _question => widget.questions[_index];

  void _select(int option) {
    setState(() {
      // Tapping the chosen option again clears it.
      if (_responses[_question.id] == option) {
        _responses.remove(_question.id);
      } else {
        _responses[_question.id] = option;
      }
    });
  }

  Future<bool> _confirm(
      String title, String message, String yes, String no) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(no)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
            child: Text(yes),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _leave() async {
    final leave = await _confirm('Leave this quiz?',
        'Your answers so far will be lost.', 'Leave', 'Stay');
    if (leave && mounted) Navigator.of(context).pop();
  }

  Future<void> _askSubmit() async {
    final unanswered = _total - _responses.length;
    final message = unanswered == 0
        ? 'You answered all $_total questions.'
        : 'You answered ${_responses.length} of $_total. $unanswered ${unanswered == 1 ? 'question is' : 'questions are'} unanswered.';
    final ok = await _confirm(
        'Submit quiz?',
        '$message\nYou cannot change answers after submitting.',
        'Submit',
        'Keep going');
    if (ok && mounted) await _submit();
  }

  Future<void> _submit() async {
    final services = ServicesScope.of(context);
    setState(() => _submitting = true);
    try {
      final result = await services.attempts.submit(SubmitRequest(
        quiz: widget.quiz,
        language: _language,
        responses: Map<String, int>.of(_responses),
        startedAt: _startedAt,
        clientAttemptId: _clientAttemptId,
      ));
      services.attemptsChanged.value++;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          quiz: widget.quiz,
          questions: widget.questions,
          result: result,
          language: _language,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  void _openPalette() {
    final pal = Palette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pal.card,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_responses.length} of $_total answered',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _total; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        setState(() => _index = i);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _responses.containsKey(widget.questions[i].id)
                              ? AppColors.indigo
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == _index ? AppColors.saffron : pal.border,
                            width: i == _index ? 2.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                _responses.containsKey(widget.questions[i].id)
                                    ? Colors.white
                                    : pal.text,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _askSubmit();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: AppColors.text,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Submit quiz',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final tr = _question.inLanguage(_language);
    final chosen = _responses[_question.id];
    final isLast = _index == _total - 1;
    final languages =
        widget.quiz.languages.where(kLanguageLabels.containsKey).toList();

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : _leave),
        title: Text('Q ${_index + 1} / $_total',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        centerTitle: true,
        actions: [
          if (languages.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.translate),
              tooltip: 'Language',
              onSelected: (value) => setState(() => _language = value),
              itemBuilder: (context) => [
                for (final l in languages)
                  CheckedPopupMenuItem<String>(
                      value: l,
                      checked: l == _language,
                      child: Text(kLanguageLabels[l]!)),
              ],
            ),
          IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'All questions',
              onPressed: _openPalette),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: _responses.length / _total,
                minHeight: 4,
                color: AppColors.saffron,
                backgroundColor: pal.border,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('QUESTION ${_index + 1}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.saffron)),
                            const SizedBox(height: 8),
                            Text(tr.text,
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < tr.options.length; i++) ...[
                        OptionTile(
                          letter: 'ABCD'[i],
                          text: tr.options[i],
                          state: chosen == i
                              ? OptionState.selected
                              : OptionState.normal,
                          onTap: _submitting ? null : () => _select(i),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (chosen != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(
                                    () => _responses.remove(_question.id)),
                            child: const Text('Clear answer'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                    color: pal.card,
                    border: Border(top: BorderSide(color: pal.border))),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _index == 0 || _submitting
                              ? null
                              : () => setState(() => _index--),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : (isLast
                                  ? _askSubmit
                                  : () => setState(() => _index++)),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                isLast ? AppColors.saffron : AppColors.indigo,
                            foregroundColor:
                                isLast ? AppColors.text : Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(isLast ? 'Submit' : 'Next',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_submitting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: AppCard(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.indigo),
                        ),
                        const SizedBox(width: 14),
                        const Text('Submitting...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_submitting) _leave();
      },
      child: withLanguageFont(context, _language, scaffold),
    );
  }
}
