import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/catalog.dart';
import '../models/quiz.dart';

/// Read-only access to the published catalog. Every query filters on isPublished/status because
/// the security rules only allow students to read published items.
class CatalogRepository {
  CatalogRepository(this._db);
  final FirebaseFirestore _db;

  Future<List<ExamCategory>> categories() async {
    final snap = await _db
        .collection('categories')
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => ExamCategory.fromMap(d.id, d.data())).toList();
  }

  Future<List<Exam>> exams() async {
    final snap = await _db
        .collection('exams')
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => Exam.fromMap(d.id, d.data())).toList();
  }

  Future<List<Subject>> subjects(String examId) async {
    final snap = await _db
        .collection('subjects')
        .where('examId', isEqualTo: examId)
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList();
  }

  Future<List<Topic>> topics(String subjectId) async {
    final snap = await _db
        .collection('topics')
        .where('subjectId', isEqualTo: subjectId)
        .where('isPublished', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => Topic.fromMap(d.id, d.data())).toList();
  }

  Future<List<Quiz>> quizzes(String topicId) async {
    final snap = await _db
        .collection('quizzes')
        .where('topicId', isEqualTo: topicId)
        .where('status', isEqualTo: 'published')
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs.map((d) => Quiz.fromMap(d.id, d.data())).toList();
  }
}
