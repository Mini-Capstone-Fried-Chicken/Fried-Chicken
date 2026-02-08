import 'package:flutter/material.dart';

const Color burgundy = Color(0xFF76263D);

class LearnMorePopup extends StatelessWidget {
  final VoidCallback onClose;
  final String purposeText;
  final String facilitiesText;

  const LearnMorePopup({
    super.key,
    required this.onClose,
    this.purposeText = 'No purpose available.',
    this.facilitiesText = 'No facilities available.',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Additional Information:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  color: burgundy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  const TextSpan(
                    text: 'Purpose: ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: burgundy),
                  ),
                  TextSpan(text: purposeText),
                ],
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  const TextSpan(
                    text: 'Facilities: ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: burgundy),
                  ),
                  TextSpan(text: facilitiesText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
