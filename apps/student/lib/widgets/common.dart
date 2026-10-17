import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';

String friendlyError(Object e) {
  if (e is FirebaseFunctionsException) {
    return e.message ?? 'Could not complete the request. Please try again.';
  }
  if (e is FirebaseException) {
    if (e.code == 'permission-denied') {
      return 'You do not have access to this content.';
    }
    if (e.code == 'unavailable') {
      return 'Cannot reach the server. Check your internet and try again.';
    }
    if (e.code == 'failed-precondition' &&
        (e.message ?? '').contains('index')) {
      return 'This list is still being prepared. Please try again in a few minutes.';
    }
  }
  if (e is StateError) return e.message;
  return 'Something went wrong. Please try again.';
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String formatDate(DateTime? d) {
  if (d == null) return '';
  final local = d.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// Rebuilds when the content language changes.
class LangBuilder extends StatelessWidget {
  const LangBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, String language) builder;

  @override
  Widget build(BuildContext context) {
    final controller = ServicesScope.of(context).language;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => builder(context, controller.language),
    );
  }
}

/// Applies the agreed font for a language: Noto Sans Devanagari for Hindi, Poppins otherwise.
Widget withLanguageFont(BuildContext context, String language, Widget child) {
  final base = Theme.of(context);
  final textTheme = language == 'hi'
      ? GoogleFonts.notoSansDevanagariTextTheme(base.textTheme)
      : GoogleFonts.poppinsTextTheme(base.textTheme);
  return Theme(data: base.copyWith(textTheme: textTheme), child: child);
}

AppBar rankAppBar(BuildContext context, String title,
    {String? subtitle, List<Widget>? actions, Widget? leading}) {
  return AppBar(
    backgroundColor: AppColors.indigo,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: leading,
    actions: actions,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        if (subtitle != null)
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9C8F0))),
      ],
    ),
  );
}

/// Indigo block at the top of tab pages (Home, Practice, History, Profile).
class IndigoHeader extends StatelessWidget {
  const IndigoHeader({super.key, required this.child, this.bottomPadding = 18});
  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.indigo,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
          child: child,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16),
      this.color});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      side: BorderSide(color: pal.border),
    );
    return Material(
      color: color ?? pal.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child:
          InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class CircleInitial extends StatelessWidget {
  const CircleInitial(this.text, {super.key, this.size = 40});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    final letter = text.isEmpty
        ? '?'
        : String.fromCharCode(text.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: pal.tint, shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: pal.dark ? Colors.white : AppColors.indigo,
        ),
      ),
    );
  }
}

class NavTile extends StatelessWidget {
  const NavTile(
      {super.key,
      required this.title,
      this.subtitle,
      required this.onTap,
      this.trailing});
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleInitial(title),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: pal.muted)),
                  ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right, color: pal.muted),
        ],
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.red),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: pal.muted, fontSize: 14)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs [load] once, shows a spinner, an error with retry, or the data. [reloadOn] triggers a reload.
class AsyncView<T> extends StatefulWidget {
  const AsyncView(
      {super.key, required this.load, required this.builder, this.reloadOn});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final Listenable? reloadOn;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
    widget.reloadOn?.addListener(_reload);
  }

  @override
  void dispose() {
    widget.reloadOn?.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = widget.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.indigo));
        }
        if (snapshot.hasError) {
          return ErrorRetry(
              message: friendlyError(snapshot.error!), onRetry: _reload);
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

/// A page with a title bar and a list loaded from [load].
class ListPage<T> extends StatelessWidget {
  const ListPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.load,
    required this.itemBuilder,
    required this.emptyText,
  });

  final String title;
  final String? subtitle;
  final Future<List<T>> Function() load;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      appBar: rankAppBar(context, title, subtitle: subtitle),
      body: AsyncView<List<T>>(
        load: load,
        builder: (context, items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(emptyText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: pal.muted)),
              ),
            );
          }
          return LangBuilder(
            builder: (context, _) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => itemBuilder(context, items[i]),
            ),
          );
        },
      ),
    );
  }
}
