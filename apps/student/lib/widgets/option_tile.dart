import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

enum OptionState { normal, selected, correct, wrong }

/// One answer option (A-D). 56 dp minimum height and 14 dp corners, as agreed in the layout guide.
class OptionTile extends StatelessWidget {
  const OptionTile(
      {super.key,
      required this.letter,
      required this.text,
      required this.state,
      this.onTap});

  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    Color fill = pal.card;
    Color border = pal.border;
    double borderWidth = 1;
    Color badgeBg = pal.tint;
    Color badgeFg = pal.dark ? Colors.white : AppColors.indigo;
    IconData? trailing;
    Color? trailingColor;

    switch (state) {
      case OptionState.normal:
        break;
      case OptionState.selected:
        fill = pal.tint;
        border = AppColors.indigo;
        borderWidth = 2;
        badgeBg = AppColors.indigo;
        badgeFg = Colors.white;
        break;
      case OptionState.correct:
        fill = pal.correctTint;
        border = AppColors.green;
        borderWidth = 2;
        badgeBg = AppColors.green;
        badgeFg = Colors.white;
        trailing = Icons.check_circle;
        trailingColor = AppColors.green;
        break;
      case OptionState.wrong:
        fill = pal.wrongTint;
        border = AppColors.red;
        borderWidth = 2;
        badgeBg = AppColors.red;
        badgeFg = Colors.white;
        trailing = Icons.cancel;
        trailingColor = AppColors.red;
        break;
    }

    return Material(
      color: fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.optionRadius),
        side: BorderSide(color: border, width: borderWidth),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.optionHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                  child: Text(letter,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: badgeFg)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(text,
                        style: const TextStyle(fontSize: 16, height: 1.35))),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailing, color: trailingColor, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
