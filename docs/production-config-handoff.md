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

rules の SHA は、`competitionSeasonMemberships` の `allow read: if true` を含むコミット以降であること。indexes の SHA は、`teams` の `competitionKey + nameJa`、`competitionKey + searchKeywords`、`sportKey` の同形、および `games` の `homeTeamId` / `awayTeamId` 複合索引を含むコミット以降であること。Google カレンダー、Apple カレンダー、ICS を渡すときは Functions の行も埋める。PR #53 の日本語名をそのカレンダーに出すとき、Functions の SHA は `1fe5ecc` 以降である。#53 自体は rules と indexes の行を要求しない。

## 実機に渡す前の最小確認

1. 渡すビルドは `USE_SAMPLE_DATA` なし。release の `bool.fromEnvironment('USE_SAMPLE_DATA')` は false で、本番 Firebase を読む。
2. 上の台帳で、そのビルドが依存する行が埋まっている。検索とリーグ一覧だけなら rules と indexes。Google カレンダーや Apple / ICS を触るなら Functions も。
3. 「チームを探す」で、文字を入れないサッカーのホーム、文字を入れた検索、サッカーのリーグから Jリーグ、の3つを開き、出たエラー文字列をそのまま残す。`エラー: $e` は診断用なので、汎用文言に置き換えない。
4. リーグ一覧が `エラー:` で止まる場合、それは「チームが無い」ではない。`permission-denied` は membership の rules 未反映の候補である。一覧が「このリーグのチームはまだありません」なら、読み取りは通っており、ドキュメントが無い（または legacy のチームも無い）状態である。
5. アプリ内の日本語名は、PR #53 を含むクライアントの再ビルドと再インストールで確認する。対象は `football_j*`（`football_j2_j3_special` を含む）と `football_emperor_cup` で、プレミアリーグを含む海外競技は英語のままである。Google Calendar、Apple Calendar、ICS の同じ名前は、Functions の行が `1fe5ecc` 以降のときだけ確認する。#53 のために rules のデプロイ、indexes のデプロイ、Firestore への書き込み、API sync はしない。

## 成果物の分類

| 成果物 | 分類 |
| --- | --- |
| Flutter の画面とナビゲーション | client-only |
| アプリ内のチーム表示名 | client-only。PR #53 の日本語名は再ビルドと再インストールで反映される |
| Google Calendar / Apple Calendar / ICS のチーム表示名 | functions-deploy-required。PR #53 の日本語名は本番 Functions のデプロイが要る。rules、indexes、Firestore への書き込み、API sync は不要 |
| `lib/firebase_options.dart`、`android/app/google-services.json`、`ios/Runner/GoogleService-Info.plist` | client-only（アプリに同梱。本番プロジェクト ID は一致） |
| 生成済み presentation catalog | Dart は client-only。`functions/` の catalog は、カレンダー名を本番に載せるとき functions-deploy-required |
| `firestore.rules` | rules-deploy-required |
| `firestore.indexes.json` | indexes-deploy-required |
| `functions/**`、`firebase.json` の functions 設定 | functions-deploy-required |
| Google Calendar の OAuth クライアントと Secret Manager | external-console-required。Functions 未デプロイでも動かない |
| Apple Sign-In / Apple Developer | external-console-required。リポジトリの V1 手順は Google ログインを先にし、Apple 設定は Store 公開時 |
| Firestore の teams / games / membership ドキュメント | data-write-required。未投入は空一覧であり、設定エラーではない |
| `subscriptions` | rules にはある。Flutter クライアントは読んでいない |
| `translationMaps` | rules は公開 read。書くのは Functions / seed。Flutter は読んでいない |

## 直近 main の分類

現行 main は `1fe5ecc`（PR #53 のマージ）である。

| 変更 | 分類 |
| --- | --- |
| PR #53 日本語国内サッカーの表示名（マージ `1fe5ecc`、実装 `f2f27d9`） | Flutter の表示名ポリシーと Functions のカレンダー / ICS 表示名ポリシーの両方。`football_j*`（`football_j2_j3_special` を含む）と `football_emperor_cup` は日本語。プレミアリーグを含む海外競技は英語。アプリ内の名前は client-only（再ビルドと再インストール）。Google Calendar、Apple Calendar、ICS の名前は functions-deploy-required。rules のデプロイ、indexes のデプロイ、Firestore への書き込み、API sync は不要 |
| PR #52 試合カードの枠（`25be9d0`） | client-only |
| PR #51 フォロー検索の表示名（`f28ca9a`） | client-only |
| PR #50 スタジアム / 移動の表示（`1ee3c1c`） | client-only |
| PR #49 競技内のホーム / リーグ（`0771b7b`） | 画面は client-only。`af1109b` の `competitionSeasonMemberships` 公開 read は rules-deploy-required。このコミットは indexes を変えていない |
| 検索の競技スコープ（`d750918`） | client-only。空クエリは単一フィールド。文字ありは既存の複合索引に依存 |
| キーワード検索の複合索引（`9b4f041`）と試合索引（`107c6e6`） | indexes-deploy-required |
| Google カレンダー Functions（`5f98262`）と Node 22（`5f0204b`） | functions-deploy-required。OAuth secret は external-console-required |
| チーム / 試合の seed と sync | data-write-required。実機インストールだけでは走らない |

## 画面と本番依存

読み取りルールは、現行 `firestore.rules` では `teams` / `leagues` / `games` / `competitionSeasonMemberships` / `translationMaps` が公開 read、`users` は本人のみ、Google カレンダーの3コレクションはクライアント拒否、`subscriptions` は本人のみ。Functions は Admin SDK なので rules を迂回して書く。

| 画面 | リポジトリ | クエリ | ルール | 複合索引 | Functions | 欠けると |
| --- | --- | --- | --- | --- | --- | --- |
| サインイン | Firebase Auth。プロフィールは `users/{uid}` の get / set | ドキュメント get。複合クエリなし | create は `email`、`followedTeamIds`、`preferredLanguage`（`ja` / `en`）が必要 | 不要 | 不要 | Auth 設定または users rules が古いとプロフィール作成が失敗 |
| ホーム | `followedTeamsProvider`、`fetchUpcomingGamesForTeams` | チームは `documentId whereIn`（30件）。試合は `homeTeamId` / `awayTeamId` の `whereIn` + `startTimeUTC` 範囲 + `orderBy` | teams / games は公開 read。users は本人 | 試合の2フィールド索引。チーム ID は単一フィールド | 不要 | 試合索引が無いとホームは `エラー: $e`。チーム索引の欠落ではこのクエリは落ちない |
| フォロー / 解除 | `followTeam` / `unfollowTeam` | `users/{uid}` を読んでから update。`followedTeamIds` の arrayUnion / arrayRemove に加え、キーが無いときだけ `preferredLanguage: ja` と、Auth に email があるときだけ `email` を同じ update に足す。既存の値は上書きしない | update 後のドキュメントが `email`、`followedTeamIds`、`preferredLanguage` を持つこと | 不要 | フォロー変更の Google 同期は `syncGoogleCalendarOnFollowChange`。未デプロイでもフォロー自体は成功し、カレンダーだけ追従しない | キーが無いレガシー文書は、次のフォロー操作で不足キーを足す。本番の一括移行はしない。Auth email も無い文書は update が拒否され得る。検索一覧の読み取りとは別 |
| チームを探す / 競技ホーム | `searchTeamsForSportTab` → `searchTeams` | 空文字は `fetchTeams`。`competitionKey` と legacy `sportKey` の等価。文字ありは `nameJa` 範囲、または `searchKeywords` array-contains を、その等価と組み合わせる | teams 公開 read | 空文字は不要。文字ありは `competitionKey`/`sportKey` + `nameJa`、および + `searchKeywords` | 不要 | 文字ありで索引が無いと `failed-precondition` が `エラー: $e`。空文字ではその索引は使わない |
| 競技のリーグ一覧 | `SportLeagueBrowser` | Firestore なし。`SportsRegistry` の有効な競技だけ | 不要 | 不要 | 不要 | この画面単独では本番設定で落ちない |
| リーグのチーム一覧 | `CompetitionTeamListingService` | `competitionSeasonMemberships` を `competitionKey` 等価。ID があれば `documentId whereIn`。無ければ `fetchTeams` | membership の公開 read が本番に無いと default deny | membership と ID 取得は単一フィールド。カードの次戦はホームと同じ試合索引 | 不要 | rules 未反映は `エラー: $error` で止まり、空一覧にしない。ドキュメント欠如は legacy へ落ち、それも空なら「このリーグのチームはまだありません」 |
| チーム詳細 | `fetchTeam`、`fetchUpcomingGamesForTeam`、`watchUpcomingGamesForTeam` | ドキュメント get。次戦は `homeTeamId` または `awayTeamId` + `status` + `startTimeUTC`。watch は home のみ + `startTimeUTC`（status なし） | teams / games 公開 read | 3フィールド索引と、watch 用の2フィールド索引 | 不要 | 索引が無いと試合側が `エラー: $e`。チーム get は索引不要 |
| スケジュール | `fetchScheduleGamesForTeams` | `homeTeamId` / `awayTeamId` の `whereIn` + `orderBy startTimeUTC`。未来フィルタなし | games 公開 read | 2フィールド索引 | 不要 | 索引が無いと `エラー: $e` |
| Google カレンダー | `GoogleCalendarConnectionRepository` | Firestore 直読みなし。callable | 接続ドキュメントはクライアント拒否 | 不要 | `beginGoogleCalendarConnection`、`getGoogleCalendarConnectionStatus`、`syncGoogleCalendarNow`、`disconnectGoogleCalendar`、HTTPS `googleCalendarOAuthCallback` | Functions または OAuth secret が無いと接続できない。検索一覧とは独立。表示名は PR #53 の Functions ポリシー |
| Apple / ICS | `CalendarFeedRepository`、`IcsUrlBuilder` | フィード token は callable。ICS は HTTPS `getCalendar` | users の `followedTeamIds` を Functions が読む | 試合の取得は Functions 側。クライアントのスケジュール索引とは別 | `ensureCalendarFeed`、`rotateCalendarFeed`、`getCalendar` | Functions 未デプロイは URL 購読が失敗。検索一覧とは独立。表示名は PR #53 の Functions ポリシー |

サッカーのホームが空クエリで読む競技は、有効なレジストリのうち `football_j1` と `football_premier` だけである。J2 / J3 / 百年構想リーグは、このホーム検索のクエリ対象ではない。

PR #53 の表示名は、上の Firestore クエリを変えていない。アプリ内のホーム、検索、リーグ、スケジュール、チーム詳細は、クライアントの再ビルドと再インストールで日本語になる。Google Calendar、Apple Calendar、ICS は、本番 Functions が `1fe5ecc` のポリシーを実行するまで、国内クラブが英語のままになり得る。この差は rules、indexes、試合データの有無とは別である。

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
| プロフィールの読み取りエラー | `followedTeamIdsProvider` はエラーのままなので、フォロー中は空一覧にせず `エラー: $e` になる |
| サインイン済みでプロフィール文書が無い | 未サインインではない。フォローは書かない。ホームは「サインインが必要です」にせず「プロフィールを確認できません」 |
| 未サインイン | プロフィール stream は null。フォロー一覧は空。エラーではない |

開いた直後の「チームを探す」は初期タブがフォロー中で、隣接タブは野球である。サッカーのホームと Jリーグは、そこへ移動するまでクエリされない。直後の `エラー` から、membership 未反映と、文字あり検索の複合索引は外せる。残るのは teams の read 拒否、通信失敗、チーム文書の型不一致（`nameEn` / `nameJa` / `leagueId` のキャスト）である。本番文書は読んでいないので、型不一致は未確認である。

ホームの `エラー: $e` の近くに「チームを探す」ボタンがある。ホームはフォロー中の試合複合索引を使う。検索画面のタイトル直下の `エラー` とは別経路である。
