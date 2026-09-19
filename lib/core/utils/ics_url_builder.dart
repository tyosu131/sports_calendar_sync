/// Builds iCalendar subscription URLs served by Cloud Functions.
///
/// The Cloud Function dynamically generates a .ics file containing all
/// games for the user's followed teams.
class IcsUrlBuilder {
  IcsUrlBuilder._();

  static const _region = 'asia-northeast1';
  static const _projectId = 'sports-calendar-sync-a4564';
  static const _functionName = 'getCalendar';

  static String buildForToken(String token) {
    return Uri.https(
      '$_region-$_projectId.cloudfunctions.net',
      '/$_functionName',
      {'token': token},
    ).toString();
  }
}
