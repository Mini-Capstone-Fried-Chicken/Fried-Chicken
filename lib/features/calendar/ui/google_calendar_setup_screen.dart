import 'package:flutter/material.dart';

class GoogleCalendarSetupScreen extends StatelessWidget {
  const GoogleCalendarSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF7F1D3A),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 12),
              const Text(
                'How to set up your Google Calendar',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Follow these steps to properly set up your Google Calendar to work with the Campus App.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              _StepSection(
                title: 'Step 1',
                description:
                    'Click on the + sign at the bottom right of your screen and choose event.',
                imagePath: 'assets/images/google_calendar_step1.png',
              ),
              const SizedBox(height: 28),

              _StepSection(
                title: 'Step 2',
                description:
                    'Set the location of the event as the building name/code your class is in and the description as the room number.',
                imagePath: 'assets/images/google_calendar_step2.png',
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepSection extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  const _StepSection({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}