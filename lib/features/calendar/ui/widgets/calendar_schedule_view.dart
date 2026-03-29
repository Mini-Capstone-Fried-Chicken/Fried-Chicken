import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:ui';

import '../../../saved/saved_directions_controller.dart';
import '../../data/models/google_calendar_event.dart';
import '../../services/calendar_building_resolver.dart';
import '../../services/calendar_today_highlight_helper.dart';
import 'calendar_event_popup.dart';
import 'google_calendar_data_source.dart';

class CalendarScheduleView extends StatefulWidget {
  final String selectedCalendarLabel;
  final List<GoogleCalendarEvent> events;
  final VoidCallback onBack;
  final bool highContrastMode;

  final void Function(GoogleCalendarEvent event, String buildingCode)?
  onGoToBuilding;
  final void Function(
    GoogleCalendarEvent event,
    String buildingCode,
    String roomNumber,
  )?
  onGoToRoom;
  final void Function(GoogleCalendarEvent event, String buildingCode)? onSave;

  const CalendarScheduleView({
    super.key,
    required this.selectedCalendarLabel,
    required this.events,
    required this.onBack,
    this.highContrastMode = false,
    this.onGoToBuilding,
    this.onGoToRoom,
    this.onSave,
  });

  @override
  State<CalendarScheduleView> createState() => _CalendarScheduleViewState();
}

class _CalendarScheduleViewState extends State<CalendarScheduleView> {
  CalendarView _calendarView = CalendarView.week;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = widget.highContrastMode;
    final primaryText = isHighContrast ? Colors.white : Colors.black87;
    final secondaryText = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);
    final emptyStateTextColor = isHighContrast
        ? Colors.white70
        : Colors.black54;

    final calendarBackgroundColor = isHighContrast
        ? const Color(0xFF0F0F0F)
        : Colors.white;

    final calendarCellBorderColor = isHighContrast
        ? const Color(0x3389D9C2)
        : const Color(0x1A000000);

    final timeTextColor = isHighContrast ? Colors.white : Colors.black54;

    final dataSource = GoogleCalendarDataSource(widget.events);

    DateTime initialDate;
    if (widget.events.isNotEmpty && widget.events.first.start != null) {
      initialDate = widget.events.first.start!;
    } else {
      initialDate = DateTime.now();
    }

    final calendarTodayHighlightColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);

    final calendarSelectionBorderColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);

    final calendarHeaderBackgroundColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : null;

    final calendarHeaderTextColor = isHighContrast ? Colors.black : primaryText;

    const viewHeaderDayTextColor = Colors.black54;

    final viewHeaderDateTextColor = isHighContrast
        ? Colors.black
        : Colors.black87;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: isHighContrast ? const Color(0xFF89D9C2) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Class Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.selectedCalendarLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _viewChip('Day', CalendarView.day),
              const SizedBox(width: 8),
              _viewChip('Week', CalendarView.week),
              const SizedBox(width: 8),
              _viewChip('Month', CalendarView.month),
              const SizedBox(width: 8),
              _viewChip('Schedule', CalendarView.schedule),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: widget.events.isEmpty
              ? Center(
                  child: Text(
                    'No events found in this calendar.',
                    style: TextStyle(fontSize: 15, color: emptyStateTextColor),
                  ),
                )
              : SfCalendar(
                  key: ValueKey(_calendarView),
                  view: _calendarView,
                  dataSource: dataSource,
                  backgroundColor: calendarBackgroundColor,
                  cellBorderColor: calendarCellBorderColor,
                  initialDisplayDate: initialDate,
                  firstDayOfWeek: 1,
                  todayHighlightColor: calendarTodayHighlightColor,
                  specialRegions: buildTodayHighlightRegion(_calendarView),
                  selectionDecoration: BoxDecoration(
                    border: Border.all(
                      color: calendarSelectionBorderColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  headerStyle: CalendarHeaderStyle(
                    backgroundColor: calendarHeaderBackgroundColor,
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: calendarHeaderTextColor,
                    ),
                  ),
                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: calendarBackgroundColor,
                    dayTextStyle: TextStyle(color: viewHeaderDayTextColor),
                    dateTextStyle: TextStyle(color: viewHeaderDateTextColor),
                  ),
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                    showAgenda: true,
                  ),
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 22,
                    timeIntervalHeight: 60,
                    timeTextStyle: TextStyle(
                      color: timeTextColor,
                      fontSize: 12,
                    ),
                    minimumAppointmentDuration: const Duration(minutes: 45),
                  ),
                  onTap: handleCalendarTap,
                ),
        ),
      ],
    );
  }

  void handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.appointment &&
        details.targetElement != CalendarElement.agenda) {
      return;
    }

    final rawAppointment =
        details.appointments != null && details.appointments!.isNotEmpty
        ? details.appointments!.first
        : null;

    if (rawAppointment is! GoogleCalendarEvent) return;

    showEventPopup(rawAppointment);
  }

  void showEventPopup(GoogleCalendarEvent event) {
    final buildingCode = resolveBuildingCode(event.location);
    final roomNumber = (event.description ?? '').trim();

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: const Color(0xFF8B1E3F).withValues(alpha: 0.20),
            child: CalendarEventPopup(
              event: event,
              buildingCode: buildingCode,
              roomNumber: roomNumber,
              onClose: () {
                Navigator.of(context).pop();
              },
              onGoToBuilding: () {
                Navigator.of(context).pop();
                SavedDirectionsController.requestDirectionsToBuildingCode(
                  buildingCode,
                );
                widget.onGoToBuilding?.call(event, buildingCode);
              },
              onGoToRoom: () {
                Navigator.of(context).pop();
                SavedDirectionsController.requestDirectionsToBuildingRoom(
                  buildingCode: buildingCode,
                  roomCode: roomNumber,
                );
                widget.onGoToRoom?.call(event, buildingCode, roomNumber);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _viewChip(String label, CalendarView view) {
    final isHighContrast = widget.highContrastMode;
    final isSelected = _calendarView == view;

    final selectedColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);
    final selectedText = isHighContrast ? Colors.black : Colors.white;
    final unselectedText = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);
    final backgroundColor = isHighContrast
        ? const Color(0xFF111111)
        : Colors.white;
    final borderColor = isHighContrast
        ? const Color(0xFF89D9C2)
        : const Color(0xFF8B1E3F);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _calendarView = view;
        });
      },
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        color: isSelected ? selectedText : unselectedText,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: borderColor),
    );
  }
}
