import 'package:flutter/material.dart';

import '../data/models/calendar_connection_state.dart';
import '../data/models/google_calendar_event.dart';
import '../data/models/google_calendar_info.dart';
import '../data/repositories/google_calendar_repository.dart';
import '../services/google_calendar_session.dart';
import 'widgets/calendar_connect_view.dart';
import 'widgets/calendar_schedule_view.dart';
import 'widgets/calendar_selection_view.dart';
import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';

class CalendarScreen extends StatefulWidget {
  final bool isLoggedIn;

  const CalendarScreen({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GoogleCalendarRepository _repository = GoogleCalendarRepository.instance;
  final GoogleCalendarSession _session = GoogleCalendarSession.instance;

  CalendarConnectionStep _step = CalendarConnectionStep.connect;
  bool _isLoading = false;
  String? _error;

  List<GoogleCalendarInfo> _calendars = [];
  Set<String> _selectedCalendarIds = {};
  List<GoogleCalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();

    _step = _session.step;
    _calendars = List.from(_repository.cachedCalendars);
    _events = List.from(_repository.cachedEvents);
    _selectedCalendarIds = Set.from(_session.selectedCalendarIds);
  }

  void _saveSession() {
    _session.step = _step;
    _session.calendars = List.from(_calendars);
    _session.selectedCalendarIds = Set.from(_selectedCalendarIds);
    _session.events = List.from(_events);
    _session.isConnected = _step != CalendarConnectionStep.connect;
  }

  Future<void> _connectCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connected = await _repository.connect();

      if (!connected) {
        setState(() {
          _error = 'Connection cancelled.';
          _isLoading = false;
        });
        return;
      }

      final calendars = await _repository.getCalendars();

      setState(() {
        _calendars = calendars;
        _step = CalendarConnectionStep.selectCalendar;
        _isLoading = false;
      });

      _saveSession();
    } catch (e) {
      setState(() {
        _error = 'Failed to connect Google Calendar: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleCalendarSelection(GoogleCalendarInfo calendar) {
    setState(() {
      if (_selectedCalendarIds.contains(calendar.id)) {
        _selectedCalendarIds.remove(calendar.id);
      } else {
        _selectedCalendarIds.add(calendar.id);
      }
    });

    _repository.updateSelectedCalendars(_selectedCalendarIds.toList());
    _saveSession();
  }

  Future<void> _continueWithCalendars() async {
    if (_selectedCalendarIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selectedCalendars = _calendars
          .where((calendar) => _selectedCalendarIds.contains(calendar.id))
          .toList();

      final events = await _repository.getUpcomingEventsForCalendars(
        selectedCalendars,
      );

      setState(() {
        _events = events;
        _step = CalendarConnectionStep.schedule;
        _isLoading = false;
      });

      _saveSession();
    } catch (e) {
      setState(() {
        _error = 'Failed to load class schedule: $e';
        _isLoading = false;
      });
    }
  }

  String _selectedCalendarLabel() {
    final selected = _calendars
        .where((calendar) => _selectedCalendarIds.contains(calendar.id))
        .toList();

    if (selected.isEmpty) return '';
    if (selected.length == 1) return selected.first.name;
    return '${selected.length} calendars selected';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in first'),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            switch (_step) {
              case CalendarConnectionStep.connect:
                return CalendarConnectView(
                  isLoading: _isLoading,
                  error: _error,
                  onConnect: _connectCalendar,
                );

              case CalendarConnectionStep.selectCalendar:
                return CalendarSelectionView(
                  isLoading: _isLoading,
                  error: _error,
                  calendars: _calendars,
                  selectedCalendarIds: _selectedCalendarIds,
                  onCalendarToggled: _toggleCalendarSelection,
                  onContinue: _continueWithCalendars,
                  onSetupPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoogleCalendarSetupScreen(),
                      ),
                    );
                  },
                );

              case CalendarConnectionStep.schedule:
                return CalendarScheduleView(
                  selectedCalendarLabel: _selectedCalendarLabel(),
                  events: _events,
                  onBack: () {
                    _repository.goToSelection();
                    setState(() {
                      _step = CalendarConnectionStep.selectCalendar;
                    });
                    _saveSession();
                  },
                );
            }
          },
        ),
      ),
    );
  }
}