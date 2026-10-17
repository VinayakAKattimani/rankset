import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

/// Holds the current UI/content language and notifies listeners when it changes.
class LanguageController extends ChangeNotifier {
  String _language = 'en';
  String get language => _language;

  void setLocal(String value) {
    if (!kLanguageLabels.containsKey(value) || value == _language) return;
    _language = value;
    notifyListeners();
  }
}

/// App-wide dependencies, created once in main().
class Services {
  Services._({
    required this.db,
    required this.auth,
    required this.catalog,
    required this.quizzes,
    required this.attempts,
  });

  factory Services.create({required bool clientScoring}) {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final quizzes = QuizRepository(db);
    final AttemptRepository attempts = clientScoring
        ? ClientScoringAttemptRepository(
            db, quizzes, () => auth.currentUser!.uid)
        : ServerScoringAttemptRepository(
            db, quizzes, FirebaseFunctions.instanceFor(region: 'asia-south1'));
    return Services._(
      db: db,
      auth: auth,
      catalog: CatalogRepository(db),
      quizzes: quizzes,
      attempts: attempts,
    );
  }

  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final CatalogRepository catalog;
  final QuizRepository quizzes;
  final AttemptRepository attempts;

  final LanguageController language = LanguageController();

  /// Incremented after a quiz is submitted so Home and History reload.
  final ValueNotifier<int> attemptsChanged = ValueNotifier<int>(0);

  /// Name typed on the registration form, used when the profile document is first created.
  String? pendingDisplayName;

  /// Creates users/{uid} on first sign-in and loads the saved language preference.
  Future<void> ensureProfile(User user) async {
    final ref = db.doc('users/${user.uid}');
    final snap = await ref.get();
    if (snap.exists) {
      final lang = snap.data()?['preferredLanguage'];
      if (lang is String) language.setLocal(lang);
      return;
    }
    final typed = (pendingDisplayName ?? user.displayName ?? '').trim();
    final name = typed.isEmpty
        ? 'Student'
        : (typed.length > 60 ? typed.substring(0, 60) : typed);
    final data = <String, dynamic>{
      'displayName': name,
      'preferredLanguage': language.language,
      'createdAt': FieldValue.serverTimestamp(),
    };
    final email = user.email;
    if (email != null && email.isNotEmpty) data['email'] = email;
    await ref.set(data);
    pendingDisplayName = null;
  }

  Future<void> setLanguage(String code) async {
    language.setLocal(code);
    final user = auth.currentUser;
    if (user != null) {
      await db.doc('users/${user.uid}').update({'preferredLanguage': code});
    }
  }

  Future<void> signOut() => auth.signOut();

  /// Deletes the student's data, then the sign-in account. Throws FirebaseAuthException with code
  /// 'requires-recent-login' if the sign-in is too old; the data is already gone in that case.
  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    await _deleteAll(db.collection('attempts').where('uid', isEqualTo: uid));
    await _deleteAll(db.collection('users/$uid/completed'));
    await db.doc('users/$uid').delete();
    await user.delete();
  }

  Future<void> _deleteAll(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snap = await query.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope(
      {super.key, required this.services, required super.child});

  final Services services;

  /// Safe to call from initState because it does not register a dependency (services never change).
  static Services of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'ServicesScope is missing above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) => false;
}
