import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';
import '../services/study_stats.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final services = ServicesScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This permanently deletes your account, quiz history and results. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await services.deleteAccount();
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.code == 'requires-recent-login'
            ? 'Your data was deleted. For security, sign out, sign in again, then tap Delete account once more to finish.'
            : 'Could not delete the account. Please try again.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    final pal = Palette.of(context);
    final user = services.auth.currentUser;
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Student';
    final email = user?.email ?? '';

    return Column(
      children: [
        IndigoHeader(
          bottomPadding: 20,
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: Text(String.fromCharCode(name.runes.first).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo)),
              ),
              const SizedBox(height: 9),
              Text(name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              if (email.isNotEmpty)
                Text(email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFC9C8F0))),
            ],
          ),
        ),
        Expanded(
          child: AsyncView<List<AttemptSummary>>(
            load: () => services.attempts
                .history(services.auth.currentUser!.uid, limit: 50),
            reloadOn: services.attemptsChanged,
            builder: (context, attempts) {
              final stats = StudyStats.fromAttempts(attempts);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileStats(stats: stats),
                  const SizedBox(height: 14),
                  _RewardProgressCard(currentStreak: stats.currentStreak),
                  const SizedBox(height: 22),
                  AppCard(
                    child: LangBuilder(
                      builder: (context, lang) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Language',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              'Used for exam names and quizzes available in your language.',
                              style: TextStyle(fontSize: 12, color: pal.muted)),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: [
                              for (final entry in kLanguageLabels.entries)
                                ButtonSegment<String>(
                                    value: entry.key, label: Text(entry.value)),
                            ],
                            selected: {lang},
                            onSelectionChanged: (selection) async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await services.setLanguage(selection.first);
                              } catch (e) {
                                messenger.showSnackBar(
                                    SnackBar(content: Text(friendlyError(e))));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: services.signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _deleteAccount(context),
                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                    child: const Text('Delete account'),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('${AppBrand.name}  |  ${AppBrand.tagline}',
                        style: TextStyle(fontSize: 12, color: pal.muted)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.stats});
  final StudyStats stats;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final values = [
      ('${stats.currentStreak}', 'Streak'),
      ('${stats.bestStreak}', 'Best streak'),
      ('—', 'Points'),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) Container(width: 1, height: 40, color: pal.border),
            Expanded(
              child: Column(
                children: [
                  Text(values[i].$1,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(values[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: pal.muted)),
                  if (i == 2)
                    Text('Not tracked',
                        style: TextStyle(fontSize: 8, color: pal.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardProgressCard extends StatelessWidget {
  const _RewardProgressCard({required this.currentStreak});
  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final streakProgress = (currentStreak / 30).clamp(0.0, 1.0);
    return AppCard(
      color: pal.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rewards progress · preview only',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.indigo,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Illustrative goals · no rewards are active or earned',
              style: TextStyle(fontSize: 10, color: pal.muted)),
          const SizedBox(height: 14),
          Text('30-day streak goal · $currentStreak / 30 days',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: streakProgress,
              minHeight: 7,
              color: AppColors.saffron,
              backgroundColor: pal.card,
            ),
          ),
          const SizedBox(height: 12),
          const Text('10 rewarded-ad goal · progress not tracked',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('Rewarded ads are unavailable in this preview.',
              style: TextStyle(fontSize: 10, color: pal.muted)),
        ],
      ),
    );
  }
}
