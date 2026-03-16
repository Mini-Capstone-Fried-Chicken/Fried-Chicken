import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/calendar/data/models/calendar_connection_state.dart';

void main() {
  group('CalendarSessionState', () {

    test('initial constructor sets default values', () {
      const state = CalendarSessionState.initial();

      expect(state.isConnected, false);
      expect(state.step, CalendarConnectionStep.connect);
      expect(state.selectedCalendarIds, []);
    });

    test('constructor assigns values correctly', () {
      const state = CalendarSessionState(
        isConnected: true,
        step: CalendarConnectionStep.schedule,
        selectedCalendarIds: ['cal1', 'cal2'],
      );

      expect(state.isConnected, true);
      expect(state.step, CalendarConnectionStep.schedule);
      expect(state.selectedCalendarIds, ['cal1', 'cal2']);
    });

    test('copyWith overrides provided values', () {
      const state = CalendarSessionState(
        isConnected: false,
        step: CalendarConnectionStep.connect,
        selectedCalendarIds: [],
      );

      final updated = state.copyWith(
        isConnected: true,
        step: CalendarConnectionStep.selectCalendar,
        selectedCalendarIds: ['calendar123'],
      );

      expect(updated.isConnected, true);
      expect(updated.step, CalendarConnectionStep.selectCalendar);
      expect(updated.selectedCalendarIds, ['calendar123']);
    });

    test('copyWith keeps existing values when parameters are null', () {
      const state = CalendarSessionState(
        isConnected: true,
        step: CalendarConnectionStep.schedule,
        selectedCalendarIds: ['cal1'],
      );

      final updated = state.copyWith();

      expect(updated.isConnected, state.isConnected);
      expect(updated.step, state.step);
      expect(updated.selectedCalendarIds, state.selectedCalendarIds);
    });
  });
}