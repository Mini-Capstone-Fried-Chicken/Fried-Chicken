import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:ui';

import '../../data/models/google_calendar_event.dart';
import '../../services/calendar_building_resolver.dart';
import '../../services/calendar_today_highlight_helper.dart';
import 'calendar_event_popup.dart';
import 'google_calendar_data_source.dart';

class CalendarScheduleView extends StatefulWidget {
  final String selectedCalendarLabel;
  final List<GoogleCalendarEvent> events;
  final VoidCallback onBack;

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
    final dataSource = GoogleCalendarDataSource(widget.events);

    DateTime initialDate;
    if (widget.events.isNotEmpty && widget.events.first.start != null) {
      initialDate = widget.events.first.start!;
    } else {
      initialDate = DateTime.now();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'My Class Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B1E3F),
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
              ? const Center(
                  child: Text(
                    'No events found in this calendar.',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                )
              : SfCalendar(
                  key: ValueKey(_calendarView),
                  view: _calendarView,
                  dataSource: dataSource,
                  initialDisplayDate: initialDate,
                  firstDayOfWeek: 1,
                  todayHighlightColor: const Color(0xFF8B1E3F),
                  specialRegions: buildTodayHighlightRegion(_calendarView),
                  selectionDecoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF8B1E3F),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  headerStyle: const CalendarHeaderStyle(
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                    showAgenda: true,
                  ),
                  timeSlotViewSettings: const TimeSlotViewSettings(
                    startHour: 8,
                    endHour: 22,
                    timeIntervalHeight: 60,
                    minimumAppointmentDuration: Duration(minutes: 45),
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
            color: const Color(0xFF8B1E3F).withOpacity(0.20),
            child: CalendarEventPopup(
              event: event,
              buildingCode: buildingCode,
              roomNumber: roomNumber,
              onClose: () {
                Navigator.of(context).pop();
              },
              onGoToBuilding: () {
                Navigator.of(context).pop();
                widget.onGoToBuilding?.call(event, buildingCode);
              },
              onGoToRoom: () {
                Navigator.of(context).pop();
                widget.onGoToRoom?.call(event, buildingCode, roomNumber);
              },
              onSave: () {
                Navigator.of(context).pop();
                widget.onSave?.call(event, buildingCode);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _viewChip(String label, CalendarView view) {
    final isSelected = _calendarView == view;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _calendarView = view;
        });
      },
      selectedColor: const Color(0xFF8B1E3F),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF8B1E3F),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF8B1E3F)),
    );
  }
}
