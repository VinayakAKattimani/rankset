import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../widgets/common.dart';
import 'browse_screens.dart';
import 'premium_screen.dart';

enum PracticeMode { exams, subjects }

class _SubjectContent {
  const _SubjectContent({
    required this.subject,
    required this.quizzes,
    required this.completedQuizIds,
    required this.completionAvailable,
  });

  final Subject subject;
  final List<Quiz> quizzes;
  final Set<String> completedQuizIds;
  final bool completionAvailable;

  int get completedCount =>
      quizzes.where((quiz) => completedQuizIds.contains(quiz.id)).length;
}

class _PracticeData {
  const _PracticeData({
    required this.categories,
    required this.exams,
    required this.subjects,
  });

  final List<ExamCategory> categories;
  final List<Exam> exams;
  final List<_SubjectContent> subjects;
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    this.initialMode = PracticeMode.exams,
  });

  final PracticeMode initialMode;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _search = TextEditingController();
  late PracticeMode _mode = widget.initialMode;
  Exam? _lastOpenedExam;

  @override
  void didUpdateWidget(covariant PracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_PracticeData> _load(Services services) async {
    final categories = await services.catalog.categories();
    final exams = await services.catalog.exams();
    final subjectGroups = await Future.wait(
        exams.map((exam) => services.catalog.subjects(exam.id)));
    final subjects = subjectGroups.expand((items) => items).toList();

    final topicGroups = await Future.wait(
        subjects.map((subject) => services.catalog.topics(subject.id)));
    final topics = topicGroups.expand((items) => items).toList();
    final quizGroups = await Future.wait(
        topics.map((topic) => services.catalog.quizzes(topic.id)));
    final quizzesBySubject = <String, List<Quiz>>{
      for (final subject in subjects) subject.id: <Quiz>[],
    };
    for (var i = 0; i < topics.length; i++) {
      quizzesBySubject[topics[i].subjectId]!.addAll(quizGroups[i]);
    }

    Set<String> completed = const {};
    var completionAvailable = true;
    try {
      final userId = services.auth.currentUser!.uid;
      final snapshot =
          await services.db.collection('users/$userId/completed').get();
      completed = snapshot.docs.map((doc) => doc.id).toSet();
    } catch (_) {
      completionAvailable = false;
    }

    return _PracticeData(
      categories: categories,
      exams: exams,
      subjects: [
        for (final subject in subjects)
          _SubjectContent(
            subject: subject,
            quizzes: quizzesBySubject[subject.id]!,
            completedQuizIds: completed,
            completionAvailable: completionAvailable,
          ),
      ],
    );
  }

  void _openExam(Exam exam) {
    setState(() => _lastOpenedExam = exam);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ExamScreen(exam: exam),
    ));
  }

  void _openSubject(Subject subject) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SubjectScreen(subject: subject),
    ));
  }

  void _openPremium() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PremiumScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final pal = Palette.of(context);
    return Column(
      children: [
        IndigoHeader(
          bottomPadding: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Practice',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _search,
                builder: (context, _) => TextField(
                  controller: _search,
                  style: TextStyle(color: pal.text),
                  decoration: InputDecoration(
                    hintText: 'Search exam or subject',
                    hintStyle: TextStyle(color: pal.muted),
                    prefixIcon: Icon(Icons.search, color: pal.muted),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _search.clear,
                            icon: Icon(Icons.clear, color: pal.muted),
                          ),
                    filled: true,
                    fillColor: pal.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _PracticeModeToggle(
            selected: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
        ),
        Expanded(
          child: AsyncView<_PracticeData>(
            load: () => _load(services),
            reloadOn: services.attemptsChanged,
            builder: (context, data) => LangBuilder(
              builder: (context, lang) => ListenableBuilder(
                listenable: _search,
                builder: (context, _) => _mode == PracticeMode.exams
                    ? _buildExams(context, data, lang)
                    : _buildSubjects(context, data, lang),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExams(BuildContext context, _PracticeData data, String lang) {
    final pal = Palette.of(context);
    final query = _search.text.trim().toLowerCase();
    final visibleByCategory = <ExamCategory, List<Exam>>{};
    for (final category in data.categories) {
      final exams = data.exams
          .where((exam) => exam.categoryId == category.id)
          .where((exam) =>
              query.isEmpty ||
              exam.name.resolve(lang).toLowerCase().contains(query) ||
              category.name.resolve(lang).toLowerCase().contains(query))
          .toList();
      if (exams.isNotEmpty) visibleByCategory[category] = exams;
    }
    if (visibleByCategory.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'No exam categories are published yet.'
              : 'No sample exams match “${_search.text.trim()}”.',
          style: TextStyle(color: pal.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SampleCatalogLabel(),
        const SizedBox(height: 8),
        for (final entry in visibleByCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Text(entry.key.name.resolve(lang),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final exam in entry.value)
                    SizedBox(
                      width: cardWidth,
                      child: _ExamCard(
                        exam: exam,
                        language: lang,
                        onTap: () => _openExam(exam),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
        ],
        const Text('Continue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_lastOpenedExam == null)
          const _ContinueEmptyCard()
        else
          _ContinueExamCard(
            exam: _lastOpenedExam!,
            language: lang,
            onTap: () => _openExam(_lastOpenedExam!),
          ),
      ],
    );
  }

  Widget _buildSubjects(BuildContext context, _PracticeData data, String lang) {
    final pal = Palette.of(context);
    final query = _search.text.trim().toLowerCase();
    final subjects = data.subjects
        .where((item) =>
            query.isEmpty ||
            item.subject.name.resolve(lang).toLowerCase().contains(query))
        .toList();
    if (subjects.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'No subject areas are published yet.'
              : 'No sample subjects match “${_search.text.trim()}”.',
          style: TextStyle(color: pal.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SampleCatalogLabel(),
        const SizedBox(height: 8),
        const Text('Subject areas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final item in subjects) ...[
          _SubjectCard(
            content: item,
            language: lang,
            onTap: () => _openSubject(item.subject),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        const Text('Mock tests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _LockedPracticeCard(
          title: 'Full mock tests',
          subtitle:
              '0 available in this sample catalog · question counts unavailable',
          onGoPremium: _openPremium,
        ),
        const SizedBox(height: 18),
        const Text('Premium content',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _LockedPracticeCard(
          title: 'Notes',
          subtitle: 'Locked preview · notes are not in this catalog',
          onGoPremium: _openPremium,
        ),
        const SizedBox(height: 10),
        _LockedPracticeCard(
          title: 'MCQs',
          subtitle: 'Locked preview · no separate MCQ bank is configured',
          onGoPremium: _openPremium,
        ),
      ],
    );
  }
}

class _PracticeModeToggle extends StatelessWidget {
  const _PracticeModeToggle({required this.selected, required this.onChanged});
  final PracticeMode selected;
  final ValueChanged<PracticeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pal.tint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final mode in PracticeMode.values)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == mode
                        ? AppColors.indigo
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(mode == PracticeMode.exams ? 'Exams' : 'Subjects',
                      style: TextStyle(
                        color: selected == mode ? Colors.white : pal.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SampleCatalogLabel extends StatelessWidget {
  const _SampleCatalogLabel();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Palette.of(context).tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('SAMPLE CATALOG',
              style: TextStyle(
                  fontSize: 10,
                  color: Palette.of(context).dark
                      ? AppColors.saffron
                      : AppColors.indigo,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

class _ExamCard extends StatelessWidget {
  const _ExamCard(
      {required this.exam, required this.language, required this.onTap});
  final Exam exam;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = exam.name.resolve(language);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleInitial(title, size: 42),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ContinueEmptyCard extends StatelessWidget {
  const _ContinueEmptyCard();

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.saffron.withAlpha(150)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: AppColors.saffron),
          const SizedBox(width: 12),
          Expanded(
            child: Text('An opened exam will appear here.',
                style: TextStyle(fontSize: 12, color: pal.muted)),
          ),
        ],
      ),
    );
  }
}

class _ContinueExamCard extends StatelessWidget {
  const _ContinueExamCard(
      {required this.exam, required this.language, required this.onTap});
  final Exam exam;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Palette.of(context).card,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue: ${exam.name.resolve(language)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                const Text('Return to this exam’s subjects',
                    style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.indigo),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard(
      {required this.content, required this.language, required this.onTap});

  final _SubjectContent content;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final count = content.quizzes.length;
    final progress = content.completionAvailable && count > 0
        ? content.completedCount / count
        : 0.0;
    final progressText = !content.completionAvailable
        ? 'Progress unavailable'
        : (count == 0
            ? 'No published quizzes'
            : '${(progress * 100).round()}% complete');
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleInitial(content.subject.name.resolve(language), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.subject.name.resolve(language),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('$count quizzes · $progressText',
                    style: TextStyle(fontSize: 11, color: pal.muted)),
                if (content.completionAvailable && count > 0) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: AppColors.saffron,
                      backgroundColor: pal.border,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.indigo),
        ],
      ),
    );
  }
}

class _LockedPracticeCard extends StatelessWidget {
  const _LockedPracticeCard(
      {required this.title, required this.subtitle, required this.onGoPremium});

  final String title;
  final String subtitle;
  final VoidCallback onGoPremium;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.saffron, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.saffron, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(fontSize: 10, color: pal.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onGoPremium,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.saffron,
              foregroundColor: AppColors.text,
              minimumSize: const Size(88, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Go Premium',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
