import 'display_language_setting.dart';

/// Screen text. Japanese is the source text and the default.
///
/// When Settings selects English, [tr] returns the English text. A string
/// with no entry stays Japanese, so a missing translation is visible rather
/// than silently wrong.
///
/// Team, fighter, venue and competition names are not here: they follow
/// `TeamDisplayNamePolicy` and `CompetitionDisplayPolicy`.
String tr(String japanese) {
  if (!displayLanguageForcesEnglish) return japanese;
  return _english[japanese] ?? japanese;
}

/// `tr` for text with a value, e.g. `trArgs('{n}試合', {'n': '3'})`.
String trArgs(String japanese, Map<String, String> args) {
  var text = tr(japanese);
  args.forEach((key, value) => text = text.replaceAll('{$key}', value));
  return text;
}

bool get isEnglishUi => displayLanguageForcesEnglish;

const _english = <String, String>{
  // App / navigation
  'スポーツカレンダー': 'Sports Calendar',
  'お気に入り': 'Favorites',
  'フォロー中': 'Following',
  'フォロー': 'Follow',
  '野球': 'Baseball',
  'サッカー': 'Soccer',
  'バスケ': 'Basketball',
  'アメフト': 'American Football',
  'ホッケー': 'Hockey',
  '格闘技': 'MMA',
  'その他スポーツ': 'Other sports',
  'ホーム': 'Home',
  'リーグ': 'Leagues',
  'スケジュール': 'Schedule',
  'スケジュールを表示': 'Show schedule',
  '設定': 'Settings',
  // Home
  'チームを追加': 'Add team',
  'チームを探す': 'Find teams',
  'フォロー中のチーム': 'Followed teams',
  '直近の試合はありません': 'No upcoming games',
  'フォロー中チームの試合が追加されると、ここに表示されます。':
      'Games for the teams you follow will appear here.',
  'フォローしているチームがありません': 'You are not following any teams',
  '「チームを追加」からお気に入りのチームを登録してください。':
      'Use "Add team" to follow your favorite teams.',
  '{label}でフォローしているチームがありません':
      'You are not following any {label} teams',
  '「チームを追加」から、このスポーツのチームを登録できます。':
      'Use "Add team" to follow teams in this sport.',
  'サインインが必要です': 'Sign-in required',
  'サインイン': 'Sign in',
  'プロフィールを確認できません': 'Cannot check your profile',
  'エラー': 'Error',
  // Game card / status
  '今日': 'Today',
  '終了': 'Final',
  '延期': 'Postponed',
  '中止': 'Cancelled',
  'ホーム側': 'Home side',
  'アウェイ側': 'Away side',
  'フォロー中のチームはホーム側': 'Followed team is the home side',
  'フォロー中のチームはアウェイ側': 'Followed team is the away side',
  '現地時間': 'Local',
  '次の試合は未定': 'Next game TBD',
  // League / search
  'このリーグは見つかりません': 'League not found',
  'このリーグのチームはまだありません': 'No teams in this league yet',
  'チームが登録されると、ここに表示されます。': 'Teams will appear here once added.',
  '再試行': 'Retry',
  'フォロー解除': 'Unfollow',
  'フォローする': 'Follow',
  'リーグを検索': 'Search leagues',
  '検索をクリア': 'Clear search',
  '表示できるリーグがありません': 'No leagues to show',
  '一致するリーグはありません': 'No matching leagues',
  'チーム名で検索...': 'Search by team name...',
  'フォロー中のチームはありません': 'You are not following any teams',
  '条件に合うフォロー中のチームはありません': 'No followed teams match',
  'チームが見つかりませんでした': 'No teams found',
  // Team detail
  '直近の試合': 'Upcoming games',
  'コピーできる試合がありません': 'No games to copy',
  'ローカルICSをコピー': 'Copy local ICS',
  'ローカルICSをコピーしました': 'Local ICS copied',
  'ICSをコピー': 'Copy ICS',
  // Schedule
  '前の月': 'Previous month',
  '次の月': 'Next month',
  'フォロー中チームの試合予定': 'Schedule for followed teams',
  '日付を選択すると試合詳細を表示します': 'Select a date to see game details',
  '表示できる試合がありません': 'No games to show',
  'フォロー中チームの試合があると、ここに日付別で表示されます。':
      'Games for followed teams will appear here by date.',
  'この日の試合はありません': 'No games on this day',
  '{n}試合': '{n} games',
  '{date}の試合': 'Games on {date}',
  '日': 'Sun',
  '月': 'Mon',
  '火': 'Tue',
  '水': 'Wed',
  '木': 'Thu',
  '金': 'Fri',
  '土': 'Sat',
  'エラー: {e}': 'Error: {e}',
  '{label}': '{label}',
  '{team} のローカルICS': 'Local ICS for {team}',
  'Free MVP sample mode 用に、このチームの {n} 試合をICSテキストとして生成しました。':
      'Generated ICS text for {n} games of this team (sample mode).',
  '{year}年{month}月': '{monthName} {year}',
  '{score} 終了': '{score} Final',
  // Settings
  'アカウント': 'Account',
  'ユーザー': 'User',
  'アプリ': 'App',
  '名前の言語': 'Name language',
  'サインアウト': 'Sign out',
  'サインアウトしますか？': 'Sign out?',
  'キャンセル': 'Cancel',
  '自動（日本のチーム・選手・会場は日本語、海外は英語）':
      'Auto (Japanese teams, people and venues in Japanese; others in English)',
  'English（すべて英語）': 'English (everything in English)',
  // Sign-in
  '好きなチームの試合日程をカレンダーに同期': 'Sync your favorite teams\' schedules to your calendar',
  'Googleでサインイン': 'Sign in with Google',
  'Appleでサインイン': 'Sign in with Apple',
  'Appleでサインイン（準備中）': 'Sign in with Apple (coming soon)',
  // Calendar sync
  'カレンダーに同期': 'Sync to calendar',
  'カレンダー同期': 'Calendar sync',
  'Apple Calendarで購読': 'Subscribe in Apple Calendar',
  'Apple Calendarで開く': 'Open in Apple Calendar',
  'Apple Calendarを開けませんでした': 'Could not open Apple Calendar',
  'その他のカレンダー': 'Other calendars',
  '購読URLをコピー・共有': 'Copy or share subscription URL',
  'ICS購読URLをコピー・共有': 'Copy or share ICS subscription URL',
  '購読URLを取得できませんでした': 'Could not get the subscription URL',
  'フォロー中のチームをカレンダーに同期': 'Sync followed teams to your calendar',
  'カレンダー同期の状態を確認できません': 'Cannot check calendar sync status',
  'カレンダー同期にはサインインが必要です': 'Sign in to sync your calendar',
  'お使いのカレンダーに購読URLを登録してください。':
      'Add the subscription URL to your calendar.',
  '購読URLをコピー': 'Copy subscription URL',
  '購読URLをコピーしました': 'Subscription URL copied',
  'URLをシェア': 'Share URL',
  'スポーツカレンダー購読URL': 'Sports Calendar subscription URL',
  '確認中': 'Checking',
  '処理中': 'Working',
  '連携済み・同期中': 'Connected · syncing',
  '連携済み・同期済み': 'Connected · synced',
  '連携済み・同期エラー（タップして再試行）': 'Connected · sync error (tap to retry)',
  '再連携が必要です': 'Reconnect required',
  'エラー（タップして再試行）': 'Error (tap to retry)',
  '未連携': 'Not connected',
  '連携解除': 'Disconnect',
  '今すぐ同期': 'Sync now',
  '再連携': 'Reconnect',
  'Google Calendarと連携': 'Connect Google Calendar',
  // Follow
  'フォロー状態を確認できません': 'Cannot check follow status',
  'フォローを更新できませんでした': 'Could not update follow',
  // Policies / about
  'ページを開けませんでした。時間をおいて再度お試しください。':
      'Could not open the page. Please try again later.',
  'アプリについて': 'About',
  'プライバシーポリシー': 'Privacy policy',
  '利用規約': 'Terms of use',
  // Auth errors
  '時間をおいてもう一度お試しください。': 'Please try again later.',
  '以前利用した方法でサインインしてください。': 'Please sign in with the method you used before.',
};
