import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/calendar/data/repositories/google_calendar_repository.dart';

class SettingsScreen extends StatelessWidget {
  final bool isLoggedIn;
  final Future<void> Function(BuildContext context)? onLogoutOverride;
  final void Function(BuildContext context)? onSignInOverride;

  const SettingsScreen({
    super.key,
    required this.isLoggedIn,
    this.onLogoutOverride,
    this.onSignInOverride,
  });

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await GoogleCalendarRepository.instance.disconnect();
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _handleSignIn(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Settings Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (isLoggedIn) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  if (onLogoutOverride != null) {
                    await onLogoutOverride!(context);
                  } else {
                    await _handleLogout(context);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76263D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '(Temporary for testing)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  if (onSignInOverride != null) {
                    onSignInOverride!(context);
                  } else {
                    _handleSignIn(context);
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76263D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '(Guest mode)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}