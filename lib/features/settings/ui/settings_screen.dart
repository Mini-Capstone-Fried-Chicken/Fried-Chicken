import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:campus_app/features/calendar/data/repositories/google_calendar_repository.dart';

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

  void _syncFromSharedSettings() {
    final state = AppSettingsController.state;
    if (!mounted) return;
    setState(() {
      _accessibilityModeEnabled = state.accessibilityModeEnabled;
      _highContrastMode = state.highContrastModeEnabled;
      _largeTextMode = state.largeTextModeEnabled;
      _calendarAccessEnabled = state.calendarAccessEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    _syncFromSharedSettings();
    AppSettingsController.notifier.addListener(_syncFromSharedSettings);
  }

  @override
  void dispose() {
    AppSettingsController.notifier.removeListener(_syncFromSharedSettings);
    super.dispose();
  }

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
    final isHighContrast = _highContrastMode;
    final pageBackground = isHighContrast ? Colors.black : Colors.white;
    final cardBackground = isHighContrast
        ? const Color(0xFF0F0F0F)
        : Colors.white;
    final borderColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : Colors.grey.shade300;
    final headingColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : Colors.black87;
    final textColor = isHighContrast ? Colors.white : Colors.black87;
    final subTextColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : Colors.black87;
    final dividerColor = isHighContrast ? const Color(0x3389D9C2) : null;
    final toggleActiveColor = isHighContrast
        ? AppUiColors.highContrastPrimary
        : AppUiColors.defaultPrimary;
    final toggleInactiveThumb = isHighContrast ? Colors.white70 : null;
    final toggleInactiveTrack = isHighContrast ? Colors.white24 : null;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: AppLogo(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: cardBackground,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'General Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Default Campus',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: subTextColor,
                              ),
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
                              style: ButtonStyle(
                                foregroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return isHighContrast
                                            ? Colors.black
                                            : Colors.white;
                                      }
                                      return isHighContrast
                                          ? const Color(0xFF89D9C2)
                                          : Colors.black87;
                                    }),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return isHighContrast
                                            ? const Color(0xFF89D9C2)
                                            : AppUiColors.defaultPrimary;
                                      }
                                      return isHighContrast
                                          ? const Color(0xFF1B1B1B)
                                          : Colors.white;
                                    }),
                                side: WidgetStateProperty.all(
                                  BorderSide(
                                    color: isHighContrast
                                        ? const Color(0xFF89D9C2)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _defaultCampus = selection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Accessibility Mode',
                                style: TextStyle(color: textColor),
                              ),
                              value: _accessibilityModeEnabled,
                              activeThumbColor: toggleActiveColor,
                              inactiveThumbColor: toggleInactiveThumb,
                              inactiveTrackColor: toggleInactiveTrack,
                              onChanged: (value) {
                                setState(() {
                                  _accessibilityModeEnabled = value;
                                });
                                AppSettingsController.setAccessibilityMode(
                                  value,
                                );
                              },
                            ),
                            Divider(height: 12, color: dividerColor),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Permission Management',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: const EdgeInsets.only(left: 12),
                              title: Text(
                                'Calendar Access',
                                style: TextStyle(color: textColor),
                              ),
                              value: _calendarAccessEnabled,
                              activeThumbColor: toggleActiveColor,
                              inactiveThumbColor: toggleInactiveThumb,
                              inactiveTrackColor: toggleInactiveTrack,
                              onChanged: (value) {
                                setState(() {
                                  _calendarAccessEnabled = value;
                                });
                                AppSettingsController.setCalendarAccess(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: cardBackground,
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
                                Text(
                                  'Accessibility Settings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: headingColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Wheelchair routing as default',
                                    style: TextStyle(color: textColor),
                                  ),
                                  value: _wheelchairRoutingDefault,
                                  activeThumbColor: toggleActiveColor,
                                  inactiveThumbColor: toggleInactiveThumb,
                                  inactiveTrackColor: toggleInactiveTrack,
                                  onChanged: (value) {
                                    setState(() {
                                      _wheelchairRoutingDefault = value;
                                    });
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'High Contrast mode',
                                    style: TextStyle(color: textColor),
                                  ),
                                  value: _highContrastMode,
                                  activeThumbColor: toggleActiveColor,
                                  inactiveThumbColor: toggleInactiveThumb,
                                  inactiveTrackColor: toggleInactiveTrack,
                                  onChanged: (value) {
                                    setState(() {
                                      _highContrastMode = value;
                                    });
                                    AppSettingsController.setHighContrastMode(
                                      value,
                                    );
                                  },
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Large Text',
                                    style: TextStyle(color: textColor),
                                  ),
                                  value: _largeTextMode,
                                  activeThumbColor: toggleActiveColor,
                                  inactiveThumbColor: toggleInactiveThumb,
                                  inactiveTrackColor: toggleInactiveTrack,
                                  onChanged: (value) {
                                    setState(() {
                                      _largeTextMode = value;
                                    });
                                    AppSettingsController.setLargeTextMode(
                                      value,
                                    );
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
                    backgroundColor: AppUiColors.primary(
                      highContrastEnabled:
                          AppSettingsController.state.highContrastModeEnabled,
                    ),
                    foregroundColor: isHighContrast
                        ? Colors.black
                        : Colors.white,
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
