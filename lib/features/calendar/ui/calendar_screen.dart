import 'package:flutter/material.dart';
import 'package:campus_app/features/settings/app_settings.dart';

import '../data/models/calendar_connection_state.dart';
import '../data/models/google_calendar_event.dart';
import '../data/models/google_calendar_info.dart';
import '../data/repositories/google_calendar_repository.dart';
import '../services/google_calendar_session.dart';
import 'widgets/calendar_connect_view.dart';
import 'widgets/calendar_schedule_view.dart';
import 'widgets/calendar_selection_view.dart';
import 'package:campus_app/features/calendar/ui/google_calendar_setup_screen.dart';

abstract class CalendarRepositoryContract {
  List<GoogleCalendarInfo> get cachedCalendars;
  List<GoogleCalendarEvent> get cachedEvents;

  Future<bool> restoreConnection();
  Future<bool> connect();
  Future<List<GoogleCalendarInfo>> getCalendars();
  void updateSelectedCalendars(List<String> ids);
  Future<List<GoogleCalendarEvent>> getUpcomingEventsForCalendars(
    List<GoogleCalendarInfo> calendars,
  );
  void goToSelection();
}

abstract class CalendarSessionContract {
  bool get isConnected;
  set isConnected(bool value);

  CalendarConnectionStep get step;
  set step(CalendarConnectionStep value);

  List<GoogleCalendarInfo> get calendars;
  set calendars(List<GoogleCalendarInfo> value);

  Set<String> get selectedCalendarIds;
  set selectedCalendarIds(Set<String> value);

  List<GoogleCalendarEvent> get events;
  set events(List<GoogleCalendarEvent> value);

  Future<void> restore();
  Future<void> persist();
}

class DefaultCalendarRepositoryAdapter implements CalendarRepositoryContract {
  final GoogleCalendarRepository _repository;

  DefaultCalendarRepositoryAdapter(this._repository);

  @override
  List<GoogleCalendarInfo> get cachedCalendars => _repository.cachedCalendars;

  @override
  List<GoogleCalendarEvent> get cachedEvents => _repository.cachedEvents;

  @override
  Future<bool> restoreConnection() => _repository.restoreConnection();

  @override
  Future<bool> connect() => _repository.connect();

  @override
  Future<List<GoogleCalendarInfo>> getCalendars() => _repository.getCalendars();

  @override
  void updateSelectedCalendars(List<String> ids) {
    _repository.updateSelectedCalendars(ids);
  }

  @override
  Future<List<GoogleCalendarEvent>> getUpcomingEventsForCalendars(
    List<GoogleCalendarInfo> calendars,
  ) {
    return _repository.getUpcomingEventsForCalendars(calendars);
  }

  @override
  void goToSelection() {
    _repository.goToSelection();
  }
}

class DefaultCalendarSessionAdapter implements CalendarSessionContract {
  final GoogleCalendarSession _session;

  DefaultCalendarSessionAdapter(this._session);

  @override
  bool get isConnected => _session.isConnected;

  @override
  set isConnected(bool value) => _session.isConnected = value;

  @override
  CalendarConnectionStep get step => _session.step;

  @override
  set step(CalendarConnectionStep value) => _session.step = value;

  @override
  List<GoogleCalendarInfo> get calendars => _session.calendars;

  @override
  set calendars(List<GoogleCalendarInfo> value) => _session.calendars = value;

  @override
  Set<String> get selectedCalendarIds => _session.selectedCalendarIds;

  @override
  set selectedCalendarIds(Set<String> value) =>
      _session.selectedCalendarIds = value;

  @override
  List<GoogleCalendarEvent> get events => _session.events;

  @override
  set events(List<GoogleCalendarEvent> value) => _session.events = value;

  @override
  Future<void> restore() => _session.restore();

  @override
  Future<void> persist() => _session.persist();
}

class CalendarScreen extends StatefulWidget {
  final bool isLoggedIn;
  final CalendarRepositoryContract? repository;
  final CalendarSessionContract? session;

  const CalendarScreen({
    super.key,
    required this.isLoggedIn,
    this.repository,
    this.session,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarRepositoryContract _repository;
  late final CalendarSessionContract _session;

  CalendarConnectionStep _step = CalendarConnectionStep.connect;
  bool _isLoading = false;
  String? _error;

  List<GoogleCalendarInfo> _calendars = [];
  Set<String> _selectedCalendarIds = {};
  List<GoogleCalendarEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        DefaultCalendarRepositoryAdapter(GoogleCalendarRepository.instance);
    _session =
        widget.session ??
        DefaultCalendarSessionAdapter(GoogleCalendarSession.instance);
    _initializeCalendarState();
  }

  Future<void> _initializeCalendarState() async {
    await _session.restore();

    _step = _session.step;
    _selectedCalendarIds = Set.from(_session.selectedCalendarIds);
    _calendars = List.from(_repository.cachedCalendars);
    _events = List.from(_repository.cachedEvents);

    if (!widget.isLoggedIn) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final restored = await _repository.restoreConnection();

      if (!mounted) return;

      if (restored) {
        setState(() {
          _calendars = List.from(_repository.cachedCalendars);
          _events = List.from(_repository.cachedEvents);
          _selectedCalendarIds = Set.from(_session.selectedCalendarIds);

          if (_events.isNotEmpty) {
            _step = CalendarConnectionStep.schedule;
          } else if (_calendars.isNotEmpty) {
            _step = CalendarConnectionStep.selectCalendar;
          } else {
            _step = CalendarConnectionStep.connect;
          }
        });
      } else {
        setState(() {
          _step = CalendarConnectionStep.connect;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = CalendarConnectionStep.connect;
      });
    }
  }

  Future<void> _saveSession() async {
    _session.step = _step;
    _session.calendars = List.from(_calendars);
    _session.selectedCalendarIds = Set.from(_selectedCalendarIds);
    _session.events = List.from(_events);
    _session.isConnected = _step != CalendarConnectionStep.connect;

    await _session.persist();
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

      await _saveSession();
    } catch (e) {
      setState(() {
        _error = 'Failed to connect Google Calendar: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCalendarSelection(GoogleCalendarInfo calendar) async {
    setState(() {
      if (_selectedCalendarIds.contains(calendar.id)) {
        _selectedCalendarIds.remove(calendar.id);
      } else {
        _selectedCalendarIds.add(calendar.id);
      }
    });

    _repository.updateSelectedCalendars(_selectedCalendarIds.toList());
    await _saveSession();
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

      await _saveSession();
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

  Future<void> _goToSelection() async {
    _repository.goToSelection();
    setState(() {
      _step = CalendarConnectionStep.selectCalendar;
      _error = null;
    });
    await _saveSession();
  }

  void _openSetupScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GoogleCalendarSetupScreen(),
      ),
    );
  }

  Widget _buildBody() {
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
          onCalendarToggled: (calendar) {
            _toggleCalendarSelection(calendar);
          },
          onContinue: _continueWithCalendars,
          onSetupPressed: _openSetupScreen,
        );
      case CalendarConnectionStep.schedule:
        return CalendarScheduleView(
          selectedCalendarLabel: _selectedCalendarLabel(),
          events: _events,
          onBack: _goToSelection,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: AppSettingsController.notifier,
      builder: (context, settings, _) {
        final isHighContrast = settings.highContrastModeEnabled;

        if (!settings.calendarAccessEnabled) {
          return Scaffold(
            backgroundColor: isHighContrast
                ? Colors.black
                : const Color(0xFFF9F4F6),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 64,
                        color: isHighContrast
                            ? const Color(0xFF89D9C2)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calendar access is disabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isHighContrast
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'To use the calendar, enable Calendar Access in the Settings tab.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isHighContrast
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isHighContrast
              ? Colors.black
              : const Color(0xFFF9F4F6),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(_step), child: _buildBody()),
            ),
          ),
        );
      },
    );
  }
}
