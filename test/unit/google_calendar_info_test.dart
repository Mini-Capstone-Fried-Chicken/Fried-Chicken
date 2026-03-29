import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/features/calendar/data/models/google_calendar_info.dart';

void main() {
  group('GoogleCalendarInfo', () {
    test('constructor assigns values correctly', () {
      const calendar = GoogleCalendarInfo(
        id: 'abc123',
        name: 'My Calendar',
        isPrimary: true,
      );

      expect(calendar.id, 'abc123');
      expect(calendar.name, 'My Calendar');
      expect(calendar.isPrimary, true);
    });

    test('constructor works with non-primary calendar', () {
      const calendar = GoogleCalendarInfo(
        id: 'secondary',
        name: 'School',
        isPrimary: false,
      );

      expect(calendar.id, 'secondary');
      expect(calendar.name, 'School');
      expect(calendar.isPrimary, false);
    });
  });
}