import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz.dart';

class QuizRepository {
  QuizRepository(this._db);
  final FirebaseFirestore _db;

  Future<Quiz> quiz(String quizId) async {
    final snap = await _db.doc('quizzes/$quizId').get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('This quiz is no longer available.');
    }
    return Quiz.fromMap(snap.id, data);
  }

  /// Questions never contain answers or explanations.
  Future<List<Question>> questions(String quizId) async {
    final snap = await _db
        .collection('quizzes/$quizId/questions')
        .orderBy('order')
        .get();
    return snap.docs.map((d) => Question.fromMap(d.id, d.data())).toList();
  }

  /// Only readable after the student has completed the quiz (enforced by security rules).
  Future<Map<String, AnswerKey>> answerKeys(String quizId) async {
    final snap = await _db.collection('quizzes/$quizId/answerKeys').get();
    return {for (final d in snap.docs) d.id: AnswerKey.fromMap(d.id, d.data())};
  }
}
