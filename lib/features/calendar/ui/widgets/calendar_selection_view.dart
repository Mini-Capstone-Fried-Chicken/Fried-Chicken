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

  const CalendarSelectionView({
    super.key,
    required this.isLoading,
    required this.error,
    required this.calendars,
    required this.selectedCalendarIds,
    required this.onCalendarToggled,
    required this.onContinue,
    required this.onSetupPressed,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9D8DE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 46,
          ),
          SizedBox(height: 10),
          Text(
            'Successfully Connected!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Calendar(s)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Select one or more calendars that contain your class schedule',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onCalendarToggled(calendar),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE9D8DE)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7F1D3A)
                : Colors.grey.shade300,
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
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF7F1D3A),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onSetupPressed,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('How to set up calendar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7F1D3A),
          side: const BorderSide(color: Color(0xFF7F1D3A)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedCalendarIds.isEmpty || isLoading
            ? null
            : onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7F1D3A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
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