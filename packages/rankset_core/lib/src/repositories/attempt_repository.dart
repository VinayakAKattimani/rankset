import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/attempt.dart';
import '../models/quiz.dart';
import '../scoring.dart';
import 'quiz_repository.dart';

/// Submitting, history and result review.
///
/// Two scoring modes share this interface (see docs/ARCHITECTURE.md section 6):
///  - [ServerScoringAttemptRepository]: mode A, a Cloud Function scores (needs the Blaze plan).
///  - [ClientScoringAttemptRepository]: mode B, free fallback, the phone scores.
abstract class AttemptRepository {
  AttemptRepository(this._db, this._quizzes);

  final FirebaseFirestore _db;
  final QuizRepository _quizzes;

  /// Submits answers and returns the scored result including correct answers and explanations.
  Future<AttemptResult> submit(SubmitRequest request);

  Future<List<AttemptSummary>> history(String uid, {int limit = 50}) async {
    final snap = await _db
        .collection('attempts')
        .where('uid', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => AttemptSummary.fromMap(d.id, d.data()))
        .toList();
  }

  /// Rebuilds the full result of an earlier attempt from its stored answers + the answer keys
  /// (readable because the student completed the quiz).
  Future<AttemptResult> loadResult(String attemptId) async {
    final snap = await _db.doc('attempts/$attemptId').get();
    final data = snap.data();
    if (!snap.exists || data == null) throw StateError('Attempt not found.');
    final quizId = data['quizId'] as String;
    final quiz = await _quizzes.quiz(quizId);
    final keys = await _quizzes.answerKeys(quizId);
    final raw = data['responses'];
    final responses = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is num) responses[k] = v.toInt();
      });
    }
    return ScoreCalculator.score(
      attemptId: attemptId,
      quizId: quizId,
      questionIds: quiz.questionIds,
      responses: responses,
      keys: keys,
      language: (data['language'] as String?) ?? 'en',
    );
  }
}

/// Mode A. The function validates, scores, saves the attempt and returns the result.
class ServerScoringAttemptRepository extends AttemptRepository {
  ServerScoringAttemptRepository(super.db, super.quizzes, this._functions);
  final FirebaseFunctions _functions;

  @override
  Future<AttemptResult> submit(SubmitRequest request) async {
    final callable = _functions.httpsCallable('submitAttempt');
    final response = await callable.call(<String, dynamic>{
      'quizId': request.quiz.id,
      'language': request.language,
      'responses': request.responses,
      'clientAttemptId': request.clientAttemptId,
      'startedAtMs': request.startedAt.millisecondsSinceEpoch,
    });
    return AttemptResult.fromCallable(
        Map<String, dynamic>.from(response.data as Map));
  }
}

/// Mode B (free fallback). Flow: write a PENDING attempt + completion marker in one batch, read the
/// now-unlocked answer keys, score on the phone, then finalise the attempt once.
/// The stored score is client-computed (scoreSource == 'client'); see the architecture doc.
class ClientScoringAttemptRepository extends AttemptRepository {
  ClientScoringAttemptRepository(super.db, super.quizzes, this._uid);
  final String Function() _uid;

  @override
  Future<AttemptResult> submit(SubmitRequest request) async {
    final uid = _uid();
    final Quiz quiz = request.quiz;
    final attemptRef = _db.collection('attempts').doc();

    final batch = _db.batch();
    batch.set(attemptRef, <String, dynamic>{
      'uid': uid,
      'quizId': quiz.id,
      'quizTitle': quiz.title.toMap(),
      'examId': quiz.examId,
      'subjectId': quiz.subjectId,
      'topicId': quiz.topicId,
      'language': request.language,
      'startedAt': Timestamp.fromDate(request.startedAt),
      'submittedAt': FieldValue.serverTimestamp(),
      'responses': request.responses,
      'score': 0,
      'total': quiz.questionCount,
      'correct': 0,
      'wrong': 0,
      'unanswered': quiz.questionCount,
      'scoreSource': 'pending',
    });
    batch.set(_db.doc('users/$uid/completed/${quiz.id}'), <String, dynamic>{
      'attemptId': attemptRef.id,
      'completedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    final keys = await _quizzes.answerKeys(quiz.id);
    final result = ScoreCalculator.score(
      attemptId: attemptRef.id,
      quizId: quiz.id,
      questionIds: quiz.questionIds,
      responses: request.responses,
      keys: keys,
      language: request.language,
    );
    await attemptRef.update(<String, dynamic>{
      'score': result.score,
      'correct': result.correct,
      'wrong': result.wrong,
      'unanswered': result.unanswered,
      'scoreSource': 'client',
    });
    return result;
  }
}
