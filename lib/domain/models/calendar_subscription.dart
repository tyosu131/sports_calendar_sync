import '../../core/utils/app_constants.dart';
import 'firestore_decode.dart';

/// Represents a user's calendar subscription for a team
class CalendarSubscription {
  const CalendarSubscription({
    required this.uid,
    required this.teamId,
    required this.icsUrl,
    this.googleCalendarId,
    this.isActive = true,
  });

  final String uid;
  final String teamId;

  /// iCalendar URL served by Cloud Functions
  /// Uses an opaque feed token; Firebase UIDs are never URL credentials.
  final String icsUrl;

  /// Google Calendar ID if synced via Google Calendar API
  final String? googleCalendarId;

  final bool isActive;

  factory CalendarSubscription.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    final decoder = FirestoreDecoder(
      collection: AppConstants.subscriptionsCollection,
      documentId: docId,
    );
    return CalendarSubscription(
      uid: decoder.require<String>(data, 'uid', expected: 'String'),
      teamId: decoder.require<String>(data, 'teamId', expected: 'String'),
      icsUrl: decoder.require<String>(data, 'icsUrl', expected: 'String'),
      googleCalendarId: decoder.optional<String>(
        data,
        'googleCalendarId',
        expected: 'String',
      ),
      // Absent means active. A present non-bool is invalid.
      isActive:
          decoder.optional<bool>(data, 'isActive', expected: 'bool') ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'teamId': teamId,
      'icsUrl': icsUrl,
      if (googleCalendarId != null) 'googleCalendarId': googleCalendarId,
      'isActive': isActive,
    };
  }
}
