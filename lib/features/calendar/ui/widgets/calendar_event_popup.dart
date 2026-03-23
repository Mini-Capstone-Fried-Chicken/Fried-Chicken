import 'package:flutter/material.dart';

import '../../data/models/google_calendar_event.dart';

class CalendarEventPopup extends StatelessWidget {
  final GoogleCalendarEvent event;
  final String buildingCode;
  final String roomNumber;
  final VoidCallback onGoToBuilding;
  final VoidCallback onGoToRoom;
  final VoidCallback onSave;
  final VoidCallback onClose;

  static const String popupKey = 'calendar_event_popup';
  static const String closeButtonKey = 'calendar_popup_close_button';
  static const String goToBuildingButtonKey =
      'calendar_popup_go_to_building_button';
  static const String goToRoomButtonKey = 'calendar_popup_go_to_room_button';
  static const String saveButtonKey = 'calendar_popup_save_button';

  const CalendarEventPopup({
    super.key,
    required this.event,
    required this.buildingCode,
    required this.roomNumber,
    required this.onGoToBuilding,
    required this.onGoToRoom,
    required this.onSave,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final safeBuildingCode = buildingCode.trim();
    final safeRoomNumber = roomNumber.trim();

    final hasBuilding = safeBuildingCode.isNotEmpty;
    final hasRoom = safeRoomNumber.isNotEmpty;

    String locationLabel;

    if (hasBuilding && hasRoom) {
      locationLabel = '$safeBuildingCode-$safeRoomNumber';
    } else if (hasBuilding) {
      locationLabel = '$safeBuildingCode - No room';
    } else if (hasRoom) {
      locationLabel = 'Unknown building-$safeRoomNumber';
    } else {
      locationLabel = 'Location unavailable';
    }

    final canGoToBuilding = hasBuilding;
    final canGoToRoom = hasBuilding && hasRoom;
    final canSave = hasBuilding;

    return Dialog(
      key: const Key(popupKey),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 90),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B1E3F), width: 1.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                key: const Key(closeButtonKey),
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 18, color: Color(0xFF8B1E3F)),
                ),
              ),
            ),
            Text(
              event.title.trim().isEmpty ? 'Untitled event' : event.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              locationLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            popupButton(
              key: const Key(goToBuildingButtonKey),
              label: 'Go to Building',
              onPressed: canGoToBuilding ? onGoToBuilding : null,
            ),
            const SizedBox(height: 8),
            popupButton(
              key: const Key(goToRoomButtonKey),
              label: 'Go to Room',
              onPressed: canGoToRoom ? onGoToRoom : null,
            ),
            const SizedBox(height: 8),
            popupButton(
              key: const Key(saveButtonKey),
              label: 'Save',
              onPressed: canSave ? onSave : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget popupButton({
    required String label,
    required VoidCallback? onPressed,
    Key? key,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        key: key,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF8B1E3F),
          disabledBackgroundColor: const Color(0xFFD7AAB8),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
