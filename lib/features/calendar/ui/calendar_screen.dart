import 'package:flutter/material.dart';
import 'package:campus_app/features/settings/app_settings.dart';

class CalendarScreen extends StatelessWidget {
  final bool isLoggedIn;
  const CalendarScreen({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: AppSettingsController.notifier,
      builder: (context, settings, _) {
        final isHighContrast = settings.highContrastModeEnabled;
        return Scaffold(
          backgroundColor: isHighContrast ? Colors.black : Colors.white,
          body: Center(
            child: Text(
              'Calendar Screen',
              style: TextStyle(
                color: isHighContrast
                    ? const Color(0xFF89D9C2)
                    : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}