import 'package:flutter/material.dart';

import '../../data/models/google_calendar_info.dart';

class CalendarSelectionView extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<GoogleCalendarInfo> calendars;
  final Set<String> selectedCalendarIds;
  final void Function(GoogleCalendarInfo calendar) onCalendarToggled;
  final VoidCallback onContinue;
  final VoidCallback onSetupPressed;
  final bool highContrastMode;

  const CalendarSelectionView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.calendars,
    required this.selectedCalendarIds,
    required this.onCalendarToggled,
    required this.onContinue,
    required this.onSetupPressed,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuccessBanner(),
          const SizedBox(height: 28),
          _buildHeader(),
          if (error != null) ...[
            const SizedBox(height: 12),
            _buildErrorText(),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCalendarList(),
          ),
          const SizedBox(height: 12),
          _buildSetupButton(),
          const SizedBox(height: 12),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    final bg = highContrastMode ? const Color(0xFF89D9C2) : const Color(0xFFE9D8DE);
    final textColor = highContrastMode ? Colors.black : Colors.black87;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: highContrastMode ? Colors.black : Colors.green,
            size: 46,
          ),
          const SizedBox(height: 10),
          Text(
            'Successfully Connected!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final primaryText = highContrastMode ? Colors.white : Colors.black87;
    final secondaryText = highContrastMode ? Colors.white70 : Colors.black54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Calendar(s)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select one or more calendars that contain your class schedule',
          style: TextStyle(
            fontSize: 14,
            color: secondaryText,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorText() {
    return Text(
      error!,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCalendarList() {
    return ListView.separated(
      itemCount: calendars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final calendar = calendars[index];
        final isSelected = selectedCalendarIds.contains(calendar.id);

        return _buildCalendarTile(calendar, isSelected);
      },
    );
  }

  Widget _buildCalendarTile(
    GoogleCalendarInfo calendar,
    bool isSelected,
  ) {
    final tileBg = isSelected
        ? (highContrastMode ? const Color(0xFF89D9C2) : const Color(0xFFE9D8DE))
        : (highContrastMode ? const Color(0xFF111111) : Colors.grey.shade100);
    final border = isSelected
        ? (highContrastMode ? const Color(0xFF89D9C2) : const Color(0xFF7F1D3A))
        : (highContrastMode ? const Color(0x3389D9C2) : Colors.grey.shade300);
    final textColor = highContrastMode
        ? (isSelected ? Colors.black : Colors.white)
        : Colors.black87;
    final checkColor = highContrastMode ? Colors.black : const Color(0xFF7F1D3A);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onCalendarToggled(calendar),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                calendar.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: checkColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupButton() {
    final fg = highContrastMode ? const Color(0xFF89D9C2) : const Color(0xFF7F1D3A);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onSetupPressed,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('How to set up calendar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: BorderSide(color: fg),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final bg = highContrastMode ? const Color(0xFF89D9C2) : const Color(0xFF7F1D3A);
    final fg = highContrastMode ? Colors.black : Colors.white;
    final disabledBg = highContrastMode ? Colors.white24 : Colors.grey.shade300;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedCalendarIds.isEmpty || isLoading
            ? null
            : onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: disabledBg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}