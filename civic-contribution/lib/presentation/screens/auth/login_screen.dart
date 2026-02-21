import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/data/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Login screen. Single responsibility: Google sign-in entry point.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _signingIn = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      // Opens the system browser for Google OAuth. The session is delivered
      // via the deep-link callback to authStateChanges, which causes GoRouter
      // to redirect away from /login automatically.
      await context.read<AuthService>().signInWithGoogle();
      // Reset spinner — if the user cancels the browser we land back here.
      if (mounted) setState(() => _signingIn = false);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _signingIn = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Sign-in failed. Please try again.';
          _signingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.location_city, size: 72, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'CivicPulse',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Report and track civic issues in your community.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _signingIn ? null : _signInWithGoogle,
                icon: _signingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label:
                    Text(_signingIn ? 'Signing in...' : 'Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
