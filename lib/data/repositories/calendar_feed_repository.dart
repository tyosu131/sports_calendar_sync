import 'package:cloud_functions/cloud_functions.dart';

typedef CalendarFeedCallable = Future<Object?> Function(String name);

/// Returned when the callable succeeds but does not honor the feed contract.
class InvalidCalendarFeedResponse implements Exception {
  const InvalidCalendarFeedResponse();
}

/// Small data boundary for the authenticated personalized calendar callables.
class CalendarFeedRepository {
  CalendarFeedRepository({required CalendarFeedCallable call}) : _call = call;

  factory CalendarFeedRepository.firebase({FirebaseFunctions? functions}) {
    final client = functions ??
        FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    return CalendarFeedRepository(
      call: (name) async => (await client.httpsCallable(name).call()).data,
    );
  }

  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');
  final CalendarFeedCallable _call;

  Future<String> ensureCalendarFeed() => _tokenFrom('ensureCalendarFeed');

  Future<String> rotateCalendarFeed() => _tokenFrom('rotateCalendarFeed');

  Future<String> _tokenFrom(String callableName) async {
    final result = await _call(callableName);
    if (result is! Map) throw const InvalidCalendarFeedResponse();
    final token = result['token'];
    if (token is! String || !_tokenPattern.hasMatch(token)) {
      throw const InvalidCalendarFeedResponse();
    }
    return token;
  }
}
