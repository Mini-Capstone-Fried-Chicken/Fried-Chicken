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

class _CalendarContentConfig {
  final Color emptyStateTextColor;
  final GoogleCalendarDataSource dataSource;
  final Color calendarBackgroundColor;
  final Color calendarCellBorderColor;
  final DateTime initialDate;
  final Color calendarTodayHighlightColor;
  final Color calendarSelectionBorderColor;
  final Color? calendarHeaderBackgroundColor;
  final Color calendarHeaderTextColor;
  final Color viewHeaderDateTextColor;
  final Color timeTextColor;

  const _CalendarContentConfig({
    required this.emptyStateTextColor,
    required this.dataSource,
    required this.calendarBackgroundColor,
    required this.calendarCellBorderColor,
    required this.initialDate,
    required this.calendarTodayHighlightColor,
    required this.calendarSelectionBorderColor,
    required this.calendarHeaderBackgroundColor,
    required this.calendarHeaderTextColor,
    required this.viewHeaderDateTextColor,
    required this.timeTextColor,
  });
}

class _CalendarScheduleViewState extends State<CalendarScheduleView> {
  CalendarView _calendarView = CalendarView.week;

  static const String scheduleTitleKey = 'calendar_schedule_title';
  static const String backButtonKey = 'calendar_back_button';
  static const String dayViewKey = 'calendar_day_view';
  static const String weekViewKey = 'calendar_week_view';
  static const String monthViewKey = 'calendar_month_view';
  static const String scheduleViewKey = 'calendar_schedule_view';

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
    final initialDate = _resolveInitialDate();

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

    final viewHeaderDateTextColor = isHighContrast
        ? Colors.black
        : Colors.black87;

    final contentConfig = _CalendarContentConfig(
      emptyStateTextColor: emptyStateTextColor,
      dataSource: dataSource,
      calendarBackgroundColor: calendarBackgroundColor,
      calendarCellBorderColor: calendarCellBorderColor,
      initialDate: initialDate,
      calendarTodayHighlightColor: calendarTodayHighlightColor,
      calendarSelectionBorderColor: calendarSelectionBorderColor,
      calendarHeaderBackgroundColor: calendarHeaderBackgroundColor,
      calendarHeaderTextColor: calendarHeaderTextColor,
      viewHeaderDateTextColor: viewHeaderDateTextColor,
      timeTextColor: timeTextColor,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                key: const Key(backButtonKey),
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
                  key: const Key(scheduleTitleKey),
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
              _viewChip('Day', CalendarView.day, dayViewKey),
              const SizedBox(width: 8),
              _viewChip('Week', CalendarView.week, weekViewKey),
              const SizedBox(width: 8),
              _viewChip('Month', CalendarView.month, monthViewKey),
              const SizedBox(width: 8),
              _viewChip('Schedule', CalendarView.schedule, scheduleViewKey),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildCalendarContent(contentConfig)),
      ],
    );
  }

  DateTime _resolveInitialDate() {
    if (widget.events.isNotEmpty && widget.events.first.start != null) {
      return widget.events.first.start!;
    }
    return DateTime.now();
  }

  Widget _buildCalendarContent(_CalendarContentConfig config) {
    if (widget.events.isEmpty) {
      return Center(
        child: Text(
          'No events found in this calendar.',
          style: TextStyle(fontSize: 15, color: config.emptyStateTextColor),
        ),
      );
    }

    return SfCalendar(
      key: ValueKey(_calendarView),
      view: _calendarView,
      dataSource: config.dataSource,
      backgroundColor: config.calendarBackgroundColor,
      cellBorderColor: config.calendarCellBorderColor,
      initialDisplayDate: config.initialDate,
      firstDayOfWeek: 1,
      todayHighlightColor: config.calendarTodayHighlightColor,
      specialRegions: buildTodayHighlightRegion(_calendarView),
      selectionDecoration: BoxDecoration(
        border: Border.all(
          color: config.calendarSelectionBorderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      headerStyle: CalendarHeaderStyle(
        backgroundColor: config.calendarHeaderBackgroundColor,
        textAlign: TextAlign.center,
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: config.calendarHeaderTextColor,
        ),
      ),
      viewHeaderStyle: ViewHeaderStyle(
        backgroundColor: config.calendarBackgroundColor,
        dayTextStyle: const TextStyle(color: Colors.black54),
        dateTextStyle: TextStyle(color: config.viewHeaderDateTextColor),
      ),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
      ),
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: 8,
        endHour: 22,
        timeIntervalHeight: 60,
        timeTextStyle: TextStyle(color: config.timeTextColor, fontSize: 12),
        minimumAppointmentDuration: const Duration(minutes: 45),
      ),
      onTap: handleCalendarTap,
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

  Widget _viewChip(String label, CalendarView view, String key) {
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
      key: Key(key),
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
