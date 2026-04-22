/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String teamsCollection = 'teams';
  static const String leaguesCollection = 'leagues';
  static const String gamesCollection = 'games';
  static const String subscriptionsCollection = 'subscriptions';
  static const String translationMapsCollection = 'translationMaps';

  // Supported locales
  static const List<String> supportedLocales = ['ja', 'en'];

  // Default pagination limit
  static const int defaultPageSize = 20;

  // Cache duration for game schedules
  static const Duration gameCacheDuration = Duration(hours: 1);

  // RapidAPI base URLs
  static const String rapidApiFootballBase = 'https://v3.football.api-sports.io';
  static const String rapidApiBaseballBase = 'https://v1.baseball.api-sports.io';
  static const String rapidApiBasketballBase = 'https://v1.basketball.api-sports.io';
  static const String rapidApiNbaBase = 'https://v2.nba.api-sports.io';

  // Broadcast platforms
  static const List<String> knownPlatforms = [
    'DAZN',
    'U-NEXT',
    'ABEMA',
    'NHK',
    'NHK BS',
    'フジテレビ',
    'TBS',
    'テレビ朝日',
    'スカパー!',
    'Amazon Prime Video',
    'YouTube',
  ];
}
