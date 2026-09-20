import 'package:cloud_functions/cloud_functions.dart';

typedef GoogleCalendarCallable = Future<Object?> Function(String name);

class InvalidGoogleCalendarResponse implements Exception {
  const InvalidGoogleCalendarResponse();
}

class GoogleCalendarConnectionStatus {
  const GoogleCalendarConnectionStatus({required this.connected, this.calendarName});
  final bool connected;
  final String? calendarName;
}

class GoogleCalendarConnectionRepository {
  GoogleCalendarConnectionRepository({required GoogleCalendarCallable call}) : _call = call;

  factory GoogleCalendarConnectionRepository.firebase({FirebaseFunctions? functions}) {
    final client = functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    return GoogleCalendarConnectionRepository(
      call: (name) async => (await client.httpsCallable(name).call()).data,
    );
  }

  final GoogleCalendarCallable _call;

  Future<Uri> begin() async {
    final value = await _call('beginGoogleCalendarConnection');
    if (value is! Map || value['authorizationUrl'] is! String) {
      throw const InvalidGoogleCalendarResponse();
    }
    final uri = Uri.tryParse(value['authorizationUrl'] as String);
    if (uri == null || uri.scheme != 'https' || uri.host != 'accounts.google.com') {
      throw const InvalidGoogleCalendarResponse();
    }
    return uri;
  }

  Future<GoogleCalendarConnectionStatus> status() async {
    final value = await _call('getGoogleCalendarConnectionStatus');
    if (value is! Map || value['connected'] is! bool) {
      throw const InvalidGoogleCalendarResponse();
    }
    final name = value['calendarName'];
    if (name != null && name is! String) throw const InvalidGoogleCalendarResponse();
    return GoogleCalendarConnectionStatus(connected: value['connected'] as bool, calendarName: name as String?);
  }

  Future<void> disconnect() async {
    final value = await _call('disconnectGoogleCalendar');
    if (value is! Map || value['connected'] != false) {
      throw const InvalidGoogleCalendarResponse();
    }
  }
}
