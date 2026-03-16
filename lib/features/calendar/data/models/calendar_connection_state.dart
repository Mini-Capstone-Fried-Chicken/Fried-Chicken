enum CalendarConnectionStep {
  connect,
  selectCalendar,
  schedule,
}

class CalendarSessionState {
  final bool isConnected;
  final CalendarConnectionStep step;
  final List<String> selectedCalendarIds;

  const CalendarSessionState({
    required this.isConnected,
    required this.step,
    required this.selectedCalendarIds,
  });

  const CalendarSessionState.initial()
      : isConnected = false,
        step = CalendarConnectionStep.connect,
        selectedCalendarIds = const [];

  CalendarSessionState copyWith({
    bool? isConnected,
    CalendarConnectionStep? step,
    List<String>? selectedCalendarIds,
  }) {
    return CalendarSessionState(
      isConnected: isConnected ?? this.isConnected,
      step: step ?? this.step,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
    );
  }
}