/// Builds iCalendar subscription URLs served by Cloud Functions.
///
/// URL format:
/// https://[region]-[projectId].cloudfunctions.net/getCalendar?uid=[uid]
///
/// The Cloud Function dynamically generates a .ics file containing all
/// games for the user's followed teams.
class IcsUrlBuilder {
  IcsUrlBuilder._();

  static const _region = 'asia-northeast1';
  static const _projectId = 'sports-calendar-sync-a4564';
  static const _functionName = 'getCalendar';

  static String buildForUser(String uid) {
    return 'https://$_region-$_projectId.cloudfunctions.net/$_functionName?uid=$uid';
  }

  static String buildForTeam(String uid, String teamId) {
    return 'https://$_region-$_projectId.cloudfunctions.net/$_functionName?uid=$uid&teamId=$teamId';
  }
}
