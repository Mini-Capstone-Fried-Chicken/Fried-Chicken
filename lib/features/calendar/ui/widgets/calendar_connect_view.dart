import 'package:flutter/material.dart';

class CalendarConnectView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onConnect;

  const CalendarConnectView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/logo.png',
            height: 70,
          ),
          const SizedBox(height: 48),
          const Text(
            'Connect to Google Calendar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Image.asset(
              'assets/images/google_calendar_logo.png',
              height: 60,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Connect your Google Calendar to import your class events and get directions to your next class.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 20),
            Text(
              error!,
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
              onPressed: isLoading ? null : onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F1D3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
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