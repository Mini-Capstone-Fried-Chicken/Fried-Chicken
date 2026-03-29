import 'package:campus_app/features/auth/ui/login_page.dart';
import 'package:campus_app/features/calendar/data/repositories/google_calendar_repository.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SettingsScreen({super.key, required this.isLoggedIn});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsViewStyle {
  final bool isHighContrast;
  final Color cardBackground;
  final Color borderColor;
  final Color headingColor;
  final Color textColor;
  final Color subTextColor;
  final Color? dividerColor;
  final Color toggleActiveColor;
  final Color? toggleInactiveThumb;
  final Color? toggleInactiveTrack;

  const _SettingsViewStyle({
    required this.isHighContrast,
    required this.cardBackground,
    required this.borderColor,
    required this.headingColor,
    required this.textColor,
    required this.subTextColor,
    required this.dividerColor,
    required this.toggleActiveColor,
    required this.toggleInactiveThumb,
    required this.toggleInactiveTrack,
  });
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _defaultCampus = AppSettingsState.defaultCampusSgw;
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
      _wheelchairRoutingDefault = state.wheelchairRoutingDefaultEnabled;
      _highContrastMode = state.highContrastModeEnabled;
      _largeTextMode = state.largeTextModeEnabled;
      _calendarAccessEnabled = state.calendarAccessEnabled;
      _defaultCampus = state.defaultCampus;
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
    final style = _SettingsViewStyle(
      isHighContrast: isHighContrast,
      cardBackground: cardBackground,
      borderColor: borderColor,
      headingColor: headingColor,
      textColor: textColor,
      subTextColor: subTextColor,
      dividerColor: dividerColor,
      toggleActiveColor: toggleActiveColor,
      toggleInactiveThumb: toggleInactiveThumb,
      toggleInactiveTrack: toggleInactiveTrack,
    );

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
                    const Center(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: FittedBox(fit: BoxFit.contain, child: AppLogo()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildGeneralSettingsCard(style: style),
                    const SizedBox(height: 12),
                    _buildAccessibilitySettingsCard(
                      cardBackground: cardBackground,
                      borderColor: borderColor,
                      headingColor: headingColor,
                      textColor: textColor,
                      toggleActiveColor: toggleActiveColor,
                      toggleInactiveThumb: toggleInactiveThumb,
                      toggleInactiveTrack: toggleInactiveTrack,
                    ),
                  ],
                ),
              ),
            ),
            _buildAuthButton(context, isHighContrast),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsCard({required _SettingsViewStyle style}) {
    return Card(
      color: style.cardBackground,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: style.borderColor),
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
                color: style.headingColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Default Campus',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: style.subTextColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildCampusSegmentedButton(style.isHighContrast),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Accessibility Mode',
                style: TextStyle(color: style.textColor),
              ),
              value: _accessibilityModeEnabled,
              activeThumbColor: style.toggleActiveColor,
              inactiveThumbColor: style.toggleInactiveThumb,
              inactiveTrackColor: style.toggleInactiveTrack,
              onChanged: (value) {
                setState(() {
                  _accessibilityModeEnabled = value;
                });
                AppSettingsController.setAccessibilityMode(value);
              },
            ),
            Divider(height: 12, color: style.dividerColor),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Permission Management',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: style.subTextColor,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 12),
              title: Text(
                'Calendar Access',
                style: TextStyle(color: style.textColor),
              ),
              value: _calendarAccessEnabled,
              activeThumbColor: style.toggleActiveColor,
              inactiveThumbColor: style.toggleInactiveThumb,
              inactiveTrackColor: style.toggleInactiveTrack,
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
    );
  }

  Widget _buildCampusSegmentedButton(bool isHighContrast) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(value: 'SGW', label: Text('SGW')),
        ButtonSegment<String>(value: 'Loyola', label: Text('Loyola')),
      ],
      selected: {_defaultCampus},
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isHighContrast ? Colors.black : Colors.white;
          }
          return isHighContrast ? const Color(0xFF89D9C2) : Colors.black87;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isHighContrast
                ? const Color(0xFF89D9C2)
                : AppUiColors.defaultPrimary;
          }
          return isHighContrast ? const Color(0xFF1B1B1B) : Colors.white;
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
        final selectedCampus = selection.first;
        setState(() {
          _defaultCampus = selectedCampus;
        });
        AppSettingsController.setDefaultCampus(selectedCampus);
      },
    );
  }

  Widget _buildAccessibilitySettingsCard({
    required Color cardBackground,
    required Color borderColor,
    required Color headingColor,
    required Color textColor,
    required Color toggleActiveColor,
    required Color? toggleInactiveThumb,
    required Color? toggleInactiveTrack,
  }) {
    return Card(
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
                    AppSettingsController.setWheelchairRoutingDefault(value);
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
                    AppSettingsController.setHighContrastMode(value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Large Text', style: TextStyle(color: textColor)),
                  value: _largeTextMode,
                  activeThumbColor: toggleActiveColor,
                  inactiveThumbColor: toggleInactiveThumb,
                  inactiveTrackColor: toggleInactiveTrack,
                  onChanged: (value) {
                    setState(() {
                      _largeTextMode = value;
                    });
                    AppSettingsController.setLargeTextMode(value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context, bool isHighContrast) {
    return Padding(
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
            foregroundColor: isHighContrast ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
