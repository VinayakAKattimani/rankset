import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rankset_core/rankset_core.dart';

import '../services.dart';

String authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account with this email already exists. Try signing in.';
    case 'weak-password':
      return 'Choose a stronger password (at least 6 characters).';
    case 'network-request-failed':
      return 'No internet connection. Please try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'popup-closed-by-user':
    case 'canceled':
    case 'web-context-canceled':
      return 'Sign-in was cancelled.';
    default:
      return 'Could not sign in. Please try again.';
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final services = ServicesScope.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    final name = _name.text.trim();
    if (email.isEmpty || password.isEmpty || (_registering && name.isEmpty)) {
      setState(() => _error = 'Please fill in all the fields.');
      return;
    }
    await _run(() async {
      if (_registering) {
        services.pendingDisplayName = name;
        await services.auth
            .createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await services.auth
            .signInWithEmailAndPassword(email: email, password: password);
      }
    });
  }

  Future<void> _google() async {
    final services = ServicesScope.of(context);
    await _run(() async {
      await services.auth.signInWithProvider(GoogleAuthProvider());
    });
  }

  Future<void> _forgot() async {
    final services = ServicesScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(
          () => _error = 'Type your email first, then tap "Forgot password".');
      return;
    }
    await _run(() async {
      await services.auth.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')));
    });
  }

  InputDecoration _decoration(Palette pal, String label, {Widget? suffix}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: pal.border),
    );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: pal.card,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.indigo, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = Palette.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _registering ? 'Create your account' : 'Welcome',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _registering
                    ? 'Join ${AppBrand.name} and start practising.'
                    : 'Sign in to continue with ${AppBrand.name}.',
                style: TextStyle(fontSize: 14, color: pal.muted),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: pal.text,
                  backgroundColor: pal.card,
                  side: BorderSide(color: pal.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Divider(color: pal.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: pal.muted)),
                  ),
                  Expanded(child: Divider(color: pal.border)),
                ],
              ),
              const SizedBox(height: 18),
              if (_registering) ...[
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  decoration:
                      _decoration(pal, 'Your name').copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: _decoration(pal, 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _hidePassword,
                autofillHints: const [AutofillHints.password],
                decoration: _decoration(
                  pal,
                  'Password',
                  suffix: IconButton(
                    icon: Icon(_hidePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_registering ? 'Create account' : 'Sign in'),
              ),
              if (!_registering)
                TextButton(
                    onPressed: _busy ? null : _forgot,
                    child: const Text('Forgot password?')),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _registering = !_registering;
                          _error = null;
                        }),
                child: Text(_registering
                    ? 'I already have an account'
                    : 'New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
