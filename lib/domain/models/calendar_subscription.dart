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
  /// e.g. https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar?uid=xxx
  final String icsUrl;

  /// Google Calendar ID if synced via Google Calendar API
  final String? googleCalendarId;

  final bool isActive;

  factory CalendarSubscription.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return CalendarSubscription(
      uid: data['uid'] as String,
      teamId: data['teamId'] as String,
      icsUrl: data['icsUrl'] as String,
      googleCalendarId: data['googleCalendarId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
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
