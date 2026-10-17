import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

/// Visual-only preview of the Premium paywall reference. Purchases are disabled.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 1;

  static const _benefits = [
    'Notes for every topic',
    'Unlimited MCQ practice',
    'Download quizzes as PDF',
    'All mock tests, no ads',
    'Unlock all past quizzes',
  ];

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppColors.indigo,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.saffron,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                const Text('Go Premium',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Study smarter. Revise on paper.',
                    style: TextStyle(color: Color(0xFFC9C8F0), fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              children: [
                for (final benefit in _benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF2E9E5B), size: 17),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(benefit,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PlanCard(
                        title: 'Monthly',
                        price: 'Rs 49',
                        detail: 'per month',
                        selected: _selectedPlan == 0,
                        onTap: () => setState(() => _selectedPlan = 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PlanCard(
                        title: 'Yearly',
                        price: 'Rs 399',
                        detail: 'per year',
                        badge: 'BEST VALUE',
                        selected: _selectedPlan == 1,
                        onTap: () => setState(() => _selectedPlan = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Preview only. Purchases are not available.')),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Preview only · plans and prices are examples',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: pal.muted)),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Purchases are not enabled in preview.')),
                  ),
                  style: TextButton.styleFrom(
                      foregroundColor:
                          pal.dark ? AppColors.saffron : AppColors.indigo),
                  child: const Text('Restore purchase (preview)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: selected ? pal.tint : pal.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.saffron : pal.border,
              width: selected ? 2 : 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: pal.muted)),
                const SizedBox(height: 2),
                Text(price,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(detail, style: TextStyle(fontSize: 9, color: pal.muted)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -17,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.saffron,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
