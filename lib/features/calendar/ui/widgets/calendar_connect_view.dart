import 'package:flutter/material.dart';

class CalendarConnectView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onConnect;
  final bool highContrastMode;

  const CalendarConnectView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onConnect,
    this.highContrastMode = false,
  });

  static const String connectTitleKey = 'calendar_connect_title';
  static const String connectButtonKey = 'calendar_connect_button';
  static const String connectDescriptionKey = 'calendar_connect_description';
  static const String errorTextKey = 'calendar_error_text';

  @override
  Widget build(BuildContext context) {
    final primaryText = highContrastMode ? Colors.white : Colors.black87;
    final secondaryText = highContrastMode ? Colors.white70 : Colors.black54;
    final cardBg = highContrastMode
        ? const Color(0xFF89D9C2)
        : Colors.grey.shade100;
    final buttonBg = highContrastMode
        ? const Color(0xFF89D9C2)
        : const Color(0xFF7F1D3A);
    final buttonFg = highContrastMode ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset('assets/images/logo.png', height: 70),
          const SizedBox(height: 48),
          Text(
            'Connect to Google Calendar',
            key: const Key(connectTitleKey),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/images/google_calendar_logo.png',
              height: 60,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Connect your Google Calendar to import your class events and get directions to your next class.',
            key: const Key(connectDescriptionKey),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: secondaryText, height: 1.5),
          ),
          if (error != null) ...[
            const SizedBox(height: 20),
            Text(
              error!,
              key: Key(errorTextKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key(connectButtonKey),
              onPressed: isLoading ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: buttonFg,
                      ),
                    )
                  : const Text(
                      'Connect to Google Calendar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
