# 本番設定ハンドオフ台帳

リポジトリは本番のデプロイ済みリビジョンを知らない。下の空欄は未確認である。空欄を「反映済み」と読まない。`flutter test` の成功は、Firestore rules / indexes / Functions が本番 `sports-calendar-sync-a4564` に載っていることを意味しない。

この台帳は実機へ渡す前に人が記入する。デプロイ、本番 Firestore への書き込み、API sync、OAuth / Apple Developer の変更は、このファイルだけでは行わない。

プロジェクト ID は `firebase.json`、`lib/firebase_options.dart`、Android / iOS の Firebase 設定に書いてある。`.firebaserc` はリポジトリに無い。CLI で反映する場合は `--project sports-calendar-sync-a4564` を明示する。

索引の根拠: [Firestore indexes](https://firebase.google.com/docs/firestore/query-data/indexing)。単一フィールド索引は自動作成で、`firestore.indexes.json` の `fieldOverrides` は空なので無効化していない。複合クエリだけが `indexes` 配列を必要とする。未マッチの rules は拒否される: [rules structure](https://firebase.google.com/docs/firestore/security/rules-structure)。

## 人が確認する台帳

| 本番に必要なもの | リポジトリ | 本番に反映した git SHA | 確認日 | 確認者 |
| --- | --- | --- | --- | --- |
| Firestore rules | `firestore.rules` |  |  |  |
| Firestore indexes | `firestore.indexes.json` |  |  |  |
| Functions（`asia-northeast1`） | `functions/` |  |  |  |

rules の SHA は、`competitionSeasonMemberships` の `allow read: if true` を含むコミット以降であること。indexes の SHA は、`teams` の `competitionKey + nameJa`、`competitionKey + searchKeywords`、`sportKey` の同形、および `games` の `homeTeamId` / `awayTeamId` 複合索引を含むコミット以降であること。Functions を使う画面（カレンダー接続、ICS）を渡すときは Functions の行も埋める。

## 実機に渡す前の最小確認

1. 渡すビルドは `USE_SAMPLE_DATA` なし。release の `bool.fromEnvironment('USE_SAMPLE_DATA')` は false で、本番 Firebase を読む。
2. 上の台帳で、そのビルドが依存する行が埋まっている。検索とリーグ一覧だけなら rules と indexes。Google カレンダーや Apple / ICS を触るなら Functions も。
3. 「チームを探す」で、文字を入れないサッカーのホーム、文字を入れた検索、サッカーのリーグから Jリーグ、の3つを開き、出たエラー文字列をそのまま残す。`エラー: $e` は診断用なので、汎用文言に置き換えない。
4. リーグ一覧が `エラー:` で止まる場合、それは「チームが無い」ではない。`permission-denied` は membership の rules 未反映の候補である。一覧が「このリーグのチームはまだありません」なら、読み取りは通っており、ドキュメントが無い（または legacy のチームも無い）状態である。

## 成果物の分類

| 成果物 | 分類 |
| --- | --- |
| Flutter UI / 表示名 / ナビゲーション | client-only |
| `lib/firebase_options.dart`、`android/app/google-services.json`、`ios/Runner/GoogleService-Info.plist` | client-only（アプリに同梱。本番プロジェクト ID は一致） |
| 生成済み presentation catalog（Dart / Functions JSON） | client-only。Functions のカレンダー名も同じ判定を使う場合は functions-deploy-required |
| `firestore.rules` | rules-deploy-required |
| `firestore.indexes.json` | indexes-deploy-required |
| `functions/**`、`firebase.json` の functions 設定 | functions-deploy-required |
| Google Calendar の OAuth クライアントと Secret Manager | external-console-required。Functions 未デプロイでも動かない |
| Apple Sign-In / Apple Developer | external-console-required。リポジトリの V1 手順は Google ログインを先にし、Apple 設定は Store 公開時 |
| Firestore の teams / games / membership ドキュメント | data-write-required。未投入は空一覧であり、設定エラーではない |
| `subscriptions` | rules にはある。Flutter クライアントは読んでいない |
| `translationMaps` | rules は公開 read。書くのは Functions / seed。Flutter は読んでいない |

## 直近 main の分類

| 変更 | 分類 |
| --- | --- |
| PR #52 試合カードの枠（`25be9d0`） | client-only |
| PR #51 フォロー検索の表示名（`f28ca9a`） | client-only |
| PR #50 スタジアム / 移動の表示（`1ee3c1c`） | client-only |
| PR #49 競技内のホーム / リーグ（`0771b7b`） | 画面は client-only。`af1109b` の `competitionSeasonMemberships` 公開 read は rules-deploy-required。このコミットは indexes を変えていない |
| 検索の競技スコープ（`d750918`） | client-only。空クエリは単一フィールド。文字ありは既存の複合索引に依存 |
| キーワード検索の複合索引（`9b4f041`）と試合索引（`107c6e6`） | indexes-deploy-required |
| Google カレンダー Functions（`5f98262`）と Node 22（`5f0204b`） | functions-deploy-required。OAuth secret は external-console-required |
| チーム / 試合の seed と sync | data-write-required。実機インストールだけでは走らない |

表示名の日本語国内サッカー判定は別 PR にある。この台帳のブランチは main の設定差分だけを見る。

## 画面と本番依存

読み取りルールは、現行 `firestore.rules` では `teams` / `leagues` / `games` / `competitionSeasonMemberships` / `translationMaps` が公開 read、`users` は本人のみ、Google カレンダーの3コレクションはクライアント拒否、`subscriptions` は本人のみ。Functions は Admin SDK なので rules を迂回して書く。

| 画面 | リポジトリ | クエリ | ルール | 複合索引 | Functions | 欠けると |
| --- | --- | --- | --- | --- | --- | --- |
| サインイン | Firebase Auth。プロフィールは `users/{uid}` の get / set | ドキュメント get。複合クエリなし | create は `email`、`followedTeamIds`、`preferredLanguage`（`ja` / `en`）が必要 | 不要 | 不要 | Auth 設定または users rules が古いとプロフィール作成が失敗 |
| ホーム | `followedTeamsProvider`、`fetchUpcomingGamesForTeams` | チームは `documentId whereIn`（30件）。試合は `homeTeamId` / `awayTeamId` の `whereIn` + `startTimeUTC` 範囲 + `orderBy` | teams / games は公開 read。users は本人 | 試合の2フィールド索引。チーム ID は単一フィールド | 不要 | 試合索引が無いとホームは `エラー: $e`。チーム索引の欠落ではこのクエリは落ちない |
| フォロー / 解除 | `followTeam` / `unfollowTeam` | `users/{uid}` の update。書くのは `followedTeamIds` の arrayUnion / arrayRemove だけ | update 後のドキュメントが `email`、`followedTeamIds`、`preferredLanguage` を持つこと | 不要 | フォロー変更の Google 同期は `syncGoogleCalendarOnFollowChange`。未デプロイでもフォロー自体は成功し、カレンダーだけ追従しない | 既存ユーザーに `preferredLanguage` が無いと update が拒否される。検索一覧の読み取りとは別 |
| チームを探す / 競技ホーム | `searchTeamsForSportTab` → `searchTeams` | 空文字は `fetchTeams`。`competitionKey` と legacy `sportKey` の等価。文字ありは `nameJa` 範囲、または `searchKeywords` array-contains を、その等価と組み合わせる | teams 公開 read | 空文字は不要。文字ありは `competitionKey`/`sportKey` + `nameJa`、および + `searchKeywords` | 不要 | 文字ありで索引が無いと `failed-precondition` が `エラー: $e`。空文字ではその索引は使わない |
| 競技のリーグ一覧 | `SportLeagueBrowser` | Firestore なし。`SportsRegistry` の有効な競技だけ | 不要 | 不要 | 不要 | この画面単独では本番設定で落ちない |
| リーグのチーム一覧 | `CompetitionTeamListingService` | `competitionSeasonMemberships` を `competitionKey` 等価。ID があれば `documentId whereIn`。無ければ `fetchTeams` | membership の公開 read が本番に無いと default deny | membership と ID 取得は単一フィールド。カードの次戦はホームと同じ試合索引 | 不要 | rules 未反映は `エラー: $error` で止まり、空一覧にしない。ドキュメント欠如は legacy へ落ち、それも空なら「このリーグのチームはまだありません」 |
| チーム詳細 | `fetchTeam`、`fetchUpcomingGamesForTeam`、`watchUpcomingGamesForTeam` | ドキュメント get。次戦は `homeTeamId` または `awayTeamId` + `status` + `startTimeUTC`。watch は home のみ + `startTimeUTC`（status なし） | teams / games 公開 read | 3フィールド索引と、watch 用の2フィールド索引 | 不要 | 索引が無いと試合側が `エラー: $e`。チーム get は索引不要 |
| スケジュール | `fetchScheduleGamesForTeams` | `homeTeamId` / `awayTeamId` の `whereIn` + `orderBy startTimeUTC`。未来フィルタなし | games 公開 read | 2フィールド索引 | 不要 | 索引が無いと `エラー: $e` |
| Google カレンダー | `GoogleCalendarConnectionRepository` | Firestore 直読みなし。callable | 接続ドキュメントはクライアント拒否 | 不要 | `beginGoogleCalendarConnection`、`getGoogleCalendarConnectionStatus`、`syncGoogleCalendarNow`、`disconnectGoogleCalendar`、HTTPS `googleCalendarOAuthCallback` | Functions または OAuth secret が無いと接続できない。検索一覧とは独立 |
| Apple / ICS | `CalendarFeedRepository`、`IcsUrlBuilder` | フィード token は callable。ICS は HTTPS `getCalendar` | users の `followedTeamIds` を Functions が読む | 試合の取得は Functions 側。クライアントのスケジュール索引とは別 | `ensureCalendarFeed`、`rotateCalendarFeed`、`getCalendar` | Functions 未デプロイは URL 購読が失敗。検索一覧とは独立 |

サッカーのホームが空クエリで読む競技は、有効なレジストリのうち `football_j1` と `football_premier` だけである。J2 / J3 / 百年構想リーグは、このホーム検索のクエリ対象ではない。

ロゴ用の `presentationMasterProvider` はチーム取得の失敗を空配列にする。これは試合カードを落とさないためで、検索一覧とリーグ一覧の失敗を空にするものではない。

## チームを探すで分かれ得る失敗

エラー文字列は未採取である。どの候補が実機で起きたかは、文字列と、文字を入れたか、リーグを開いたか、が分かるまで確定しない。

### A. チームを探す → サッカー → ホーム

空クエリは単一フィールドの等価だけである。現行 `indexes` に複合定義が無くても、この経路は `failed-precondition` にならない。文字を入れたときだけ複合索引が要る。

| 状態 | 結果 |
| --- | --- |
| 最新 rules + 最新 indexes | 空ならチーム一覧か「チームが見つかりませんでした」。文字ありも索引定義上は通る |
| 古い rules（membership 追加前）+ 最新アプリ | この経路は membership を読まない。teams の公開 read が残っていれば空クエリは通る |
| 最新 rules + 古い indexes | 空クエリは通る。文字ありは `failed-precondition` が `エラー: $e` |
| コレクションやドキュメントが無い | 空スナップショット。「チームが見つかりませんでした」。エラーではない |
| 未サインイン / サインイン済み | チーム read は公開。同じクエリ。フォローボタンだけ未サインイン時に `/signin` |

### B. チームを探す → サッカー → リーグ → Jリーグ

リーグ名の一覧はローカル。チーム一覧画面 `/league/football_j1` が membership を読む。等価なので複合索引は不要。

| 状態 | 結果 |
| --- | --- |
| 最新 rules + 最新 indexes | ドキュメントがあればその ID。無ければ legacy の `fetchTeams`。両方空なら空コピー |
| 古い rules + 最新アプリ | `permission-denied` が伝播し、画面は `エラー: $error`。空一覧にしない |
| 最新 rules + 古い indexes | membership の等価は通る。次戦の索引が無い場合、チーム格子は残り、次戦行だけ出ない。格子全体は `エラー` に置き換わらない |
| ドキュメントが無い | 空スナップショットのあと legacy。legacy も空なら「このリーグのチームはまだありません」（ボタン「チームを探す」）。設定エラーではない |
| 未サインイン / サインイン済み | 一覧の read は公開で同じ。フォローだけサインインが要る |

### C. フォロー中

`followedTeamIds` が空ならクエリしない。あるときは `documentId whereIn`。複合索引は不要。

| 状態 | 結果 |
| --- | --- |
| 最新 rules + 最新 indexes | ID があればチーム。無ければ「フォロー中のチームはありません」 |
| 古い rules + 最新アプリ | users の本人 read が残っていれば同じ。teams の `whereIn` も公開 read なら通る |
| 最新 rules + 古い indexes | このクエリは複合索引を使わない |
| プロフィールが読めない | `followedTeamIdsProvider` は `valueOrNull` のため空一覧になる。`エラー: $e` にはならない |
| 未サインイン | プロフィール stream は null。空メッセージ。エラーではない |

開いた直後の「チームを探す」は初期タブがフォロー中で、隣接タブは野球である。サッカーのホームと Jリーグは、そこへ移動するまでクエリされない。直後の `エラー` から、membership 未反映と、文字あり検索の複合索引は外せる。残るのは teams の read 拒否、通信失敗、チーム文書の型不一致（`nameEn` / `nameJa` / `leagueId` のキャスト）である。本番文書は読んでいないので、型不一致は未確認である。

ホームの `エラー: $e` の近くに「チームを探す」ボタンがある。ホームはフォロー中の試合複合索引を使う。検索画面のタイトル直下の `エラー` とは別経路である。
