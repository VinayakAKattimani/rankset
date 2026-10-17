import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../widgets/common.dart';
import 'quiz_screen.dart';

/// Exam -> subjects.
class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key, required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final lang = services.language.language;
    return ListPage<Subject>(
      title: exam.name.resolve(lang),
      subtitle: 'Choose a subject',
      load: () => services.catalog.subjects(exam.id),
      emptyText: 'No subjects are published for this exam yet.',
      itemBuilder: (context, subject) => LangBuilder(
        builder: (context, lang) => NavTile(
          title: subject.name.resolve(lang),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SubjectScreen(subject: subject))),
        ),
      ),
    );
  }
}

/// Subject -> topics.
class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key, required this.subject});
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final lang = services.language.language;
    return ListPage<Topic>(
      title: subject.name.resolve(lang),
      subtitle: 'Choose a topic',
      load: () => services.catalog.topics(subject.id),
      emptyText: 'No topics are published for this subject yet.',
      itemBuilder: (context, topic) => LangBuilder(
        builder: (context, lang) => NavTile(
          title: topic.name.resolve(lang),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => TopicScreen(topic: topic))),
        ),
      ),
    );
  }
}

/// Topic -> quizzes.
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.topic});
  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final lang = services.language.language;
    return ListPage<Quiz>(
      title: topic.name.resolve(lang),
      subtitle: 'Choose a quiz',
      load: () => services.catalog.quizzes(topic.id),
      emptyText: 'No quizzes are published for this topic yet.',
      itemBuilder: (context, quiz) => LangBuilder(
        builder: (context, lang) {
          final langs = quiz.languages
              .map((l) => kLanguageLabels[l] ?? l.toUpperCase())
              .join(', ');
          return NavTile(
            title: quiz.title.resolve(lang),
            subtitle: '${quiz.questionCount} questions  |  $langs',
            trailing: const Icon(Icons.play_circle_fill,
                color: AppColors.saffron, size: 30),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => QuizScreen(quiz: quiz))),
          );
        },
      ),
    );
  }
}
