import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/no_internet_screen.dart';
import 'screens/splash_screen.dart';
import 'services.dart';
import 'widgets/common.dart';

const bool _localPreview = bool.fromEnvironment('LOCAL_PREVIEW');

class RankSetApp extends StatelessWidget {
  const RankSetApp({super.key, required this.services});
  final Services services;

  @override
  Widget build(BuildContext context) {
    return ServicesScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.language,
        builder: (context, _) {
          final lang = services.language.language;
          return MaterialApp(
            title: AppBrand.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(lang),
            darkTheme: AppTheme.dark(lang),
            themeMode: ThemeMode.system,
            builder: (context, child) => SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  if (_localPreview)
                    const Material(
                      color: AppColors.saffron,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                        child: Text(
                          'LOCAL DEMO PREVIEW  •  emulator data only',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ConnectivityGate(
                        child: child ?? const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// RankSet is online-only. When the phone has no connection, a full-screen notice covers the app.
/// The app underneath stays mounted, so a quiz in progress is paused, not lost.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key, required this.child});
  final Widget child;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _offline = false;
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final dynamic result = await Connectivity().checkConnectivity();
    _apply(result);
  }

  // Newer connectivity_plus versions report a list of results, older ones a single value.
  void _apply(dynamic result) {
    final bool none = result is List
        ? (result.isEmpty || result.every((e) => e == ConnectivityResult.none))
        : result == ConnectivityResult.none;
    if (mounted && none != _offline) setState(() => _offline = none);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline) Positioned.fill(child: NoInternetScreen(onRetry: _check)),
      ],
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return StreamBuilder<User?>(
      stream: services.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return ProfileLoader(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class ProfileLoader extends StatefulWidget {
  const ProfileLoader({super.key, required this.user});
  final User user;

  @override
  State<ProfileLoader> createState() => _ProfileLoaderState();
}

class _ProfileLoaderState extends State<ProfileLoader> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() => ServicesScope.of(context).ensureProfile(widget.user);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: ErrorRetry(
              message: friendlyError(snapshot.error!),
              onRetry: () => setState(() => _future = _load()),
            ),
          );
        }
        return const MainShell();
      },
    );
  }
}
