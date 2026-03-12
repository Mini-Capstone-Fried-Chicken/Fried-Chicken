import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../data/models/google_calendar_event.dart';
import 'google_calendar_data_source.dart';

class CalendarScheduleView extends StatefulWidget {
  final String selectedCalendarLabel;
  final List<GoogleCalendarEvent> events;
  final VoidCallback onBack;

  const CalendarScheduleView({
    super.key,
    required this.selectedCalendarLabel,
    required this.events,
    required this.onBack,
  });

  @override
  State<CalendarScheduleView> createState() => _CalendarScheduleViewState();
}

class _CalendarScheduleViewState extends State<CalendarScheduleView> {
  CalendarView _calendarView = CalendarView.week;

  @override
  Widget build(BuildContext context) {
    final dataSource = GoogleCalendarDataSource(widget.events);

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
                  initialDisplayDate: widget.events.isNotEmpty
                      ? widget.events.first.start
                      : DateTime.now(),
                  firstDayOfWeek: 1,
                  todayHighlightColor: const Color(0xFF8B1E3F),
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
                  ),
                ),
        ),
      ],
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