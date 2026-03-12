import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../data/models/google_calendar_event.dart';
import '../data/models/google_calendar_info.dart';

abstract class IGoogleCalendarApi {
  Future<gcal.CalendarList> listCalendars();
  Future<gcal.Events> listEvents(String calendarId);
}

class GoogleCalendarApiAdapter implements IGoogleCalendarApi {
  final gcal.CalendarApi _api;

  GoogleCalendarApiAdapter(AuthClient client) : _api = gcal.CalendarApi(client);

  @override
  Future<gcal.CalendarList> listCalendars() {
    return _api.calendarList.list();
  }

  @override
  Future<gcal.Events> listEvents(String calendarId) {
    return _api.events.list(
      calendarId,
      timeMin: DateTime.now().toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );
  }
}

typedef CalendarApiFactory = IGoogleCalendarApi Function(AuthClient client);

class GoogleCalendarApiService {
  final CalendarApiFactory _apiFactory;

  GoogleCalendarApiService({
    CalendarApiFactory? apiFactory,
  }) : _apiFactory = apiFactory ?? ((client) => GoogleCalendarApiAdapter(client));

  Future<List<GoogleCalendarInfo>> fetchCalendars(AuthClient client) async {
    final api = _apiFactory(client);
    final response = await api.listCalendars();

    final items = response.items ?? [];

    return items
        .map(
          (item) => GoogleCalendarInfo(
            id: item.id ?? '',
            name: item.summary ?? 'Untitled calendar',
            isPrimary: item.primary ?? false,
          ),
        )
        .where((calendar) => calendar.id.isNotEmpty)
        .toList();
  }

  Future<List<GoogleCalendarEvent>> fetchUpcomingEvents(
    AuthClient client, {
    required String calendarId,
  }) async {
    final api = _apiFactory(client);
    final response = await api.listEvents(calendarId);

    final items = response.items ?? [];

    return items
        .map(
          (event) => GoogleCalendarEvent(
            id: event.id ?? '',
            title: event.summary ?? 'Untitled event',
            start: event.start?.dateTime ?? event.start?.date,
            end: event.end?.dateTime ?? event.end?.date,
            location: event.location,
            calendarId: calendarId,
            calendarName: '',
            color: const Color(0xFF8B1E3F),
          ),
        )
        .where((event) => event.id.isNotEmpty)
        .toList();
  }
}