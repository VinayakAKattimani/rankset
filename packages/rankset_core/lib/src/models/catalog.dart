import 'localized_text.dart';

class ExamCategory {
  const ExamCategory(
      {required this.id, required this.name, required this.order});
  final String id;
  final LocalizedText name;
  final int order;

  factory ExamCategory.fromMap(String id, Map<String, dynamic> m) =>
      ExamCategory(
          id: id,
          name: LocalizedText.fromMap(m['name']),
          order: asInt(m['order']));
}

class Exam {
  const Exam(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.order});
  final String id;
  final String categoryId;
  final LocalizedText name;
  final int order;

  factory Exam.fromMap(String id, Map<String, dynamic> m) => Exam(
        id: id,
        categoryId: (m['categoryId'] as String?) ?? '',
        name: LocalizedText.fromMap(m['name']),
        order: asInt(m['order']),
      );
}

class Subject {
  const Subject(
      {required this.id,
      required this.examId,
      required this.name,
      required this.order});
  final String id;
  final String examId;
  final LocalizedText name;
  final int order;

  factory Subject.fromMap(String id, Map<String, dynamic> m) => Subject(
        id: id,
        examId: (m['examId'] as String?) ?? '',
        name: LocalizedText.fromMap(m['name']),
        order: asInt(m['order']),
      );
}

class Topic {
  const Topic({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.name,
    required this.order,
  });
  final String id;
  final String examId;
  final String subjectId;
  final LocalizedText name;
  final int order;

  factory Topic.fromMap(String id, Map<String, dynamic> m) => Topic(
        id: id,
        examId: (m['examId'] as String?) ?? '',
        subjectId: (m['subjectId'] as String?) ?? '',
        name: LocalizedText.fromMap(m['name']),
        order: asInt(m['order']),
      );
}
