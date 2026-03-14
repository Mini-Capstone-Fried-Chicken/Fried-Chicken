import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SettingsScreen({super.key, required this.isLoggedIn});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultCampus = 'SGW';
  bool _accessibilityModeEnabled = false;
  bool _calendarAccessEnabled = true;

  bool _wheelchairRoutingDefault = false;
  bool _highContrastMode = false;
  bool _largeTextMode = false;

  Future<void> _handleLogout(BuildContext context) async {
    try {
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
    final borderColor = Colors.grey.shade300;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo()),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'General Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Default Campus',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'SGW',
                                  label: Text('SGW'),
                                ),
                                ButtonSegment<String>(
                                  value: 'Loyola',
                                  label: Text('Loyola'),
                                ),
                              ],
                              selected: {_defaultCampus},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _defaultCampus = selection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Assessibility Mode'),
                              value: _accessibilityModeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _accessibilityModeEnabled = value;
                                });
                              },
                            ),
                            const Divider(height: 12),
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Permission Management',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: const EdgeInsets.only(left: 12),
                              title: const Text('Calendar Access'),
                              value: _calendarAccessEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _calendarAccessEnabled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Opacity(
                          opacity: _accessibilityModeEnabled ? 1.0 : 0.5,
                          child: IgnorePointer(
                            ignoring: !_accessibilityModeEnabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Accessibility Settings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Wheelchair routing as default'),
                                  value: _wheelchairRoutingDefault,
                                  onChanged: (value) {
                                    setState(() {
                                      _wheelchairRoutingDefault = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('High Contrast mode'),
                                  value: _highContrastMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _highContrastMode = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Large Text'),
                                  value: _largeTextMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _largeTextMode = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.isLoggedIn) {
                      _handleLogout(context);
                    } else {
                      _handleSignIn(context);
                    }
                  },
                  icon: Icon(widget.isLoggedIn ? Icons.logout : Icons.login),
                  label: Text(widget.isLoggedIn ? 'Sign Out' : 'Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF76263D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
