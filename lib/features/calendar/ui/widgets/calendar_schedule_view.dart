import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../data/models/google_calendar_event.dart';
import 'google_calendar_data_source.dart';

class CalendarScheduleView extends StatefulWidget {
  final String selectedCalendarLabel;
  final List<GoogleCalendarEvent> events;
  final VoidCallback onBack;
  final bool highContrastMode;

  const CalendarScheduleView({
    super.key,
    required this.selectedCalendarLabel,
    required this.events,
    required this.onBack,
    this.highContrastMode = false,
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
    final chipSelectedBg = isHighContrast
      ? const Color(0xFF89D9C2)
      : const Color(0xFF8B1E3F);
    final chipSelectedText = isHighContrast ? Colors.black : Colors.white;
    final chipUnselectedBg = isHighContrast ? const Color(0xFF111111) : Colors.white;
    final chipUnselectedText = isHighContrast
      ? const Color(0xFF89D9C2)
      : const Color(0xFF8B1E3F);
    final chipBorder = isHighContrast
      ? const Color(0xFF89D9C2)
      : const Color(0xFF8B1E3F);

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
                    style: TextStyle(
                      fontSize: 15,
                      color: isHighContrast ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : SfCalendar(
                  key: ValueKey(_calendarView),
                  view: _calendarView,
                  dataSource: dataSource,
                  backgroundColor: isHighContrast
                      ? const Color(0xFF0F0F0F)
                      : Colors.white,
                  cellBorderColor: isHighContrast
                      ? const Color(0x3389D9C2)
                      : const Color(0x1A000000),
                  initialDisplayDate: initialDate,
                  firstDayOfWeek: 1,
                  todayHighlightColor: isHighContrast
                      ? const Color(0xFF89D9C2)
                      : const Color(0xFF8B1E3F),
                  selectionDecoration: BoxDecoration(
                    border: Border.all(
                      color: isHighContrast
                          ? const Color(0xFF89D9C2)
                          : const Color(0xFF8B1E3F),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  headerStyle: CalendarHeaderStyle(
                    backgroundColor: isHighContrast
                        ? const Color(0xFF89D9C2)
                        : null,
                    textAlign: TextAlign.center,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHighContrast ? Colors.black : primaryText,
                    ),
                  ),
                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: isHighContrast
                        ? const Color(0xFF89D9C2)
                        : Colors.white,
                    dayTextStyle: TextStyle(
                      color: isHighContrast ? Colors.black54 : Colors.black54,
                    ),
                    dateTextStyle: TextStyle(
                      color: isHighContrast ? Colors.black : Colors.black87,
                    ),
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
                      color: isHighContrast ? Colors.white : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
      ],
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
    final backgroundColor = isHighContrast ? const Color(0xFF111111) : Colors.white;
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