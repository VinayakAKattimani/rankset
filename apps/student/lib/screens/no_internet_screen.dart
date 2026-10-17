import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

/// Shown over the whole app when the phone is offline. RankSet needs internet.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: pal.wrongTint, shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_off_rounded,
                      size: 46, color: AppColors.red),
                ),
                const SizedBox(height: 26),
                const Text('No internet connection',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  'RankSet needs internet to load questions and save your results. A quiz in progress is paused until you are back online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: pal.muted, height: 1.4),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    minimumSize: const Size(160, 48),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
