import 'package:cloud_functions/cloud_functions.dart';

typedef GoogleCalendarCallable = Future<Object?> Function(String name);

class InvalidGoogleCalendarResponse implements Exception {
  const InvalidGoogleCalendarResponse();
}

class GoogleCalendarConnectionStatus {
  const GoogleCalendarConnectionStatus({required this.connected, this.calendarName, this.reauthRequired = false, this.syncStatus});
  final bool connected;
  final String? calendarName;
  final bool reauthRequired;
  final String? syncStatus;
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
    return GoogleCalendarConnectionStatus(
      connected: value['connected'] as bool, calendarName: name as String?,
      reauthRequired: value['reauthRequired'] == true,
      syncStatus: value['syncStatus'] is String ? value['syncStatus'] as String : null,
    );
  }

  /// Bounded callback-race polling. [wait] is injectable for deterministic tests.
  Future<GoogleCalendarConnectionStatus> waitForConnection({
    List<Duration> delays = const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 2),
    ],
    Future<void> Function(Duration) wait = Future<void>.delayed,
  }) async {
    var current = await status();
    for (final delay in delays) {
      if (current.connected || current.reauthRequired) break;
      await wait(delay);
      current = await status();
    }
    return current;
  }

  Future<String> syncNow() async {
    final value = await _call('syncGoogleCalendarNow');
    if (value is! Map || value['status'] is! String) throw const InvalidGoogleCalendarResponse();
    return value['status'] as String;
  }

  Future<void> disconnect() async {
    final value = await _call('disconnectGoogleCalendar');
    if (value is! Map || value['connected'] != false) {
      throw const InvalidGoogleCalendarResponse();
    }
  }
}
