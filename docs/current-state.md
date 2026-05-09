# Current State — sports_calendar_sync

> Generated: 2026-05-08  
> Based on: code inspection of all source files in `lib/` and `functions/src/`  
> Build status: `flutter pub get` ✅ / `flutter build apk --debug` ✅ / `flutter build web` ✅ / `flutter analyze --no-pub` ✅

---

## Overview

Flutter + Firebase アプリ。ユーザーがスポーツチームをフォローし、試合日程を iCalendar 形式でカレンダーアプリに同期できる。

- **Flutter**: 3.41.4 / Dart 3.11.1
- **State management**: Riverpod 2.6.1
- **Backend**: Firebase (Auth / Firestore / Cloud Functions)
- **Data source**: API-SPORTS 直契約 (API-Football v3) — サッカーのみ実装済み
- **Calendar delivery**: Cloud Functions が `.ics` ファイルを HTTP で配信

---

## Feature Status

各機能を以下の 4 区分で分類する：

- **Implemented in code** — コードが存在し、コンパイルが通る
- **Defined but not verified** — コードはあるが、実データでの動作確認が取れていない
- **Missing / incomplete** — コードが存在しない、または実装が途中
- **Blocked by data/config** — コードはあるが、外部データ・設定が不足して動作しない

### Flutter アプリ側

| 機能 | 区分 | ファイル |
|---|---|---|
| Firebase 初期化 | Implemented in code | `main.dart` |
| Google サインイン | Implemented in code / Web 対応確認済み | `sign_in_screen.dart` |
| Apple サインイン | Implemented in code | `sign_in_screen.dart` |
| サインアウト | Implemented in code | `settings_screen.dart` |
| ユーザープロフィール作成（初回サインイン時） | Google ログイン後の profile 作成確認済み | `sign_in_screen.dart`, `user_repository.dart` |
| ホーム画面（フォロー中チーム summary + 試合一覧） | Sample data で表示確認済み | `home_screen.dart` |
| チーム検索（スポーツ種別タブ + テキスト検索） | Sample data で確認済み | `team_search_screen.dart` |
| チーム詳細（試合一覧 + フォロー/解除） | Sample data で確認済み | `team_detail_screen.dart` |
| チームフォロー / アンフォロー | 鹿島アントラーズでフォロー確認済み | `user_repository.dart` |
| 設定画面（アカウント情報 / 言語切替 / サインアウト） | Defined but not verified | `settings_screen.dart` |
| iCalendar URL 生成 | URL 整合性確認済み | `ics_url_builder.dart` |
| iCalendar URL シェアシート（コピー / Google Calendar / Apple Calendar） | Defined but not verified | `ics_share_sheet.dart` |
| 試合カード表示（日時 / チーム名 / スコア / 会場 / 放送） | J1 sample games で表示確認済み | `game_card.dart` |
| 日時 JST 変換・フォーマット | Implemented in code | `date_time_utils.dart` |
| GoRouter によるルーティング（5画面） | Implemented in code | `app_router.dart` |
| Material 3 テーマ（ライト / ダーク） | Implemented in code | `main.dart` |
| 日本語ローカライゼーション設定 | Implemented in code | `main.dart` |
| `subscriptions` コレクションの CRUD | Missing / incomplete | — |
| Email / Password 認証 | Missing / incomplete | — |
| プッシュ通知（試合リマインダー） | Missing / incomplete | — |
| ページネーション / 無限スクロール | Missing / incomplete | — |
| チーム検索の全文検索 | Missing / incomplete | — |
| オフラインキャッシュ | Missing / incomplete | — |
| アセット画像（スポーツアイコン） | Missing / incomplete | `assets/` ディレクトリなし |
| ARB / 多言語対応ファイル | Missing / incomplete | ARB ファイルなし |

### Cloud Functions 側

| 機能 | 区分 | ファイル |
|---|---|---|
| `getCalendar` (HTTPS) — .ics ファイル生成・配信 | Implemented in code / deploy 未完了 | `functions/getCalendar.ts` |
| `scheduledSyncFootball` — 6時間ごとにサッカー試合データ同期 | Blocked by data/config | `index.ts`, `syncFootball.ts` |
| `triggerFootballSync` — 手動トリガー（HTTPS Callable） | Defined but not verified | `index.ts` |
| API-SPORTS → Firestore パイプライン（サッカー） | Blocked by data/config | `syncFootball.ts` |
| タイムゾーン正規化（UTC Timestamp + JST 文字列） | Implemented in code | `utils/timezone.ts` |
| チーム名翻訳マップ（英語 → 日本語） | Implemented in code | `utils/translation.ts` |
| 野球 / バスケ / アメフト / ラグビーの同期パイプライン | Missing / incomplete | — |
| 放送プラットフォーム情報の自動取得 | Missing / incomplete | `broadcastPlatforms` は常に空配列 |
| Google Calendar API 連携（自動追加） | Missing / incomplete | フィールドのみ定義 |

---

## Remaining Data / Config Gaps

Phase 1.4B 時点で sample data による最小動作は確認済み。残っているデータ・設定上の不足を切り分ける。

### 0. J.League Display Policy

Spark plan のまま Flutter アプリ側の seed data 拡充を進めるため、UI タブ表示は「Jリーグ」に寄せる。

- UI 表示: `Jリーグ`
- 内部 `competitionKey`: `football_j1` のまま維持
- 現在の seed / verify script は J1 最小データ用なので、`seedJ1Minimum.js` / `verifyJ1Minimum.js` / `seedJ1SampleGame.js` の J1 名称は維持
- 将来 J2 / J3 を追加する場合は、`football_j2` / `football_j3` として別 competition に追加する想定

### 1. Partial Firestore Seed Data

`leagues/j1_league` と `teams/kashima_antlers` は seed 済み。

- チーム検索 / チーム詳細は sample data で確認済み
- `functions/scripts/data/j1Teams.js` は data-only の J1 team master scaffold として追加済み
- `functions/scripts/seedJ1Teams.js` は confirmed team のみを seed する
- `functions/scripts/verifyJ1Teams.js` は confirmed team のみを verify する
- `functions/package.json` に `seed:j1:teams` / `verify:j1:teams` 追加済み
- generic competition team registry / seed / verify pipeline 追加済み
  - `functions/scripts/data/competitionRegistry.js`
  - `functions/scripts/seedCompetitionTeams.js`
  - `functions/scripts/verifyCompetitionTeams.js`
  - `seed:teams` / `verify:teams` npm scripts 追加済み
  - `--dry-run` 対応済み
  - current J1 20クラブ追加後の `football_j1` dry-run は PASS
- current J1 team master review document 追加済み
  - `docs/current-j1-team-master-review.md`
- `functions/scripts/data/j1Teams.js` に current J1 20クラブを confirmed team として追加済み
- `j1TeamsTodo` は空
- `node functions/scripts/seedCompetitionTeams.js football_j1` により current J1 20クラブの Firestore write 完了
- 20クラブ seed 後、field-level verification は PASS
- query check で false negative が出たため verify scripts を修正済み
- `node functions/scripts/verifyCompetitionTeams.js football_j1` は修正後 PASS
- `node functions/scripts/verifyJ1Teams.js` は修正後 PASS
- app-side team search 修正済み
  - `searchKeywords` query は raw / lowercase / uppercase / ASCII-width-normalized variants を使用
  - empty query は `[]` ではなく selected competition の teams を返す
  - Team Search screen は常に search results list path を使用
  - `\uf8ff` は `lib/` / `functions/scripts/` に残っていない
- 本番用の全リーグ・全チームデータは未投入
- 未確定チームは追加していない
- `syncFootball.ts` を本格運用するには、対象リーグ・チームの実データ整備が必要

### 2. Missing API Secret / Key Setup

API-SPORTS キーは local inspection script では動作確認済みだが、Firebase Functions の設定には入れていない。

- `scheduledSyncFootball` は起動時に `functions.config().apisports?.key` を確認し、未設定なら即 return する
- **必要な作業**: `firebase functions:config:set apisports.key=YOUR_KEY` を実行してデプロイし直す

### 3. API-SPORTS J1 Team Master Investigation

local inspection script で API-FOOTBALL の J1 team candidates を確認した。

- API key は動作確認済み
- `GET /leagues?id=98` で league id `98` が J1 League であることを確認済み
- `GET /leagues?id=98` は seasons through 2026 を含み、2026 を current として返す
- `GET /teams?league=98&season=2026` は `Count: 0`
- `GET /teams?league=98&season=2025` は `Count: 0`
- `GET /teams?league=98&season=2024` は 20 teams を返す
- `GET /leagues?country=Japan&season=2025` は Free plan 制約で `"Free plans do not have access to this season, try from 2022 to 2024."` を返す
- したがって、current J1 team master は API-SPORTS Free plan だけでは完全には導出できない
- 2024 teams を current J1 master として追加しない
- 2024 API output は API team ID / logo URL の参照用途に限定する
- active next step は official / confirmed source で current J1 team list を作り、利用可能な範囲で API team ID / logo URL を照合すること

### 4. J1 Sample Games

J1 複数チーム向けの minimal sample games は seed 済みで、Flutter 画面で表示確認済み。

- `node functions/scripts/seedJ1SampleGame.js` により Firestore へ 4件 write 完了
- `node functions/scripts/verifyJ1SampleGame.js` は PASS
- multi-follow home-screen query check は PASS
- sample game IDs:
  - `kashima_sample_001`
  - `j1_sample_osaka_derby_001`
  - `j1_sample_yokohama_tokyo_001`
  - `j1_sample_fukuoka_hiroshima_001`
- Home manual UI confirmation 済み
  - G大阪 / C大阪 follow → Osaka derby が Home に表示される
  - 横浜FM / 東京V follow → Yokohama F・Marinos vs Tokyo Verdy が Home に表示される
  - 福岡 / 広島 follow → Avispa Fukuoka vs Sanfrecce Hiroshima が Home に表示される
  - 鹿島 / 浦和 follow → Kashima Antlers vs Urawa Reds が Home に表示される
  - 関連チームを unfollow すると該当 game は Home から消える
  - follow team が 0件の場合、Home は followed-team empty state を表示する
- API-SPORTS sync による実データ投入は未完了
- `getCalendar` は `games` を読むため、deploy 後の `.ics` 実 URL 確認には対象 user profile と sample game 条件の一致が必要
- **必要な作業**: API-SPORTS sync を有効化し、実データで `games` が更新されることを確認する

### 5. Unverified Function Execution Path

Cloud Functions のデプロイ状況・実行ログが未確認。

- `firebase.json` には Functions deploy config 追加済み
- `getCalendar` の URL / function name / region / path の整合性は確認済み
- `getCalendar` は current user profile schema に対応済み
  - `followedTeamIds` が存在し、空でなければ使用
  - `followedTeamIds` が空または未定義なら `favoriteTeamIdsByCompetition` の values を flatten して fallback
- `getCalendar` の Cloud Functions deploy は未完了
- 未完了理由: Firebase Spark plan では Functions deploy ができず、Blaze plan が必要
- deploy 後、curl で `.ics` 実 URL の確認が必要

---

## Phase 1.4B Current Status

2026-05-08 時点の確認済み状態:

- Google Sign-In Web 対応完了
- J1 sample game seed / verify 完了
  - `node functions/scripts/seedJ1SampleGame.js` により 4 sample games を Firestore に write 完了
  - `node functions/scripts/verifyJ1SampleGame.js` は PASS
  - multi-follow home-screen query check は PASS
- `getCalendar` の URL 整合性確認完了
- `getCalendar` の current user schema 対応完了
  - `followedTeamIds`
  - `favoriteTeamIdsByCompetition` fallback
- `firebase.json` に Functions deploy config 追加済み
- Cloud Functions `getCalendar` deploy は未完了
- J1 team master scaffold 追加済み
  - `functions/scripts/data/j1Teams.js`
  - current J1 20クラブを confirmed team として追加済み
  - `j1TeamsTodo` は空
- confirmed team 用 seed / verify script 追加済み
  - `functions/scripts/seedJ1Teams.js`
  - `functions/scripts/verifyJ1Teams.js`
  - `verify:j1:teams` は 20クラブ seed 後 PASS
- generic competition team seed / verify pipeline 追加済み
  - `functions/scripts/data/competitionRegistry.js`
  - `functions/scripts/seedCompetitionTeams.js`
  - `functions/scripts/verifyCompetitionTeams.js`
  - `seed:teams` / `verify:teams` npm scripts 追加済み
  - generic scripts は `--dry-run` 対応
  - current J1 20クラブ追加後の `football_j1` dry-run は PASS
  - `node functions/scripts/seedCompetitionTeams.js football_j1` による Firestore write 完了
  - `node functions/scripts/verifyCompetitionTeams.js football_j1` は修正後 PASS
- current J1 team master review document 追加済み
  - `docs/current-j1-team-master-review.md`
- Team / Game model gaps analysis document 追加済み
  - `docs/team-game-model-gaps.md`
- real sync implementation priority plan 追加済み
  - `docs/real-sync-priority-plan.md`
- competition expansion roadmap 追加済み
  - `docs/competition-expansion-roadmap.md`
  - Phase 1 は football expansion: J2 / J3 から開始し、Premier League / LaLiga / Serie A / Bundesliga / Ligue 1 / UEFA competitions へ展開する方針
  - league / tournament / cup competitions は stable team master data と分離して扱う
  - team は複数 competition seasons / tournaments に所属し得る
  - J.League の division membership は team master ではなく competition season membership として扱う
  - promotion / relegation では同じ internal team ID を J1 / J2 / J3 season memberships 間で移動し、club docs を division ごとに複製しない
  - seed / verify は stable team identity と season membership を分離して確認できるようにする
  - competitionKey は stable かつ explicit に維持する
  - API availability / API IDs / team IDs / logo URLs は seedable data 化前に lookup / verify する
  - 次の実装候補は Phase 1A: `football_j2` / `football_j3` scaffold
- Phase 1A `football_j2` / `football_j3` scaffold 実装済み
  - commit: `ea16c1e Add J2 J3 competition scaffold`
  - `functions/scripts/data/competitionRegistry.js` に `football_j2` / `football_j3` を追加済み
  - stable team identity scaffold modules 追加済み
    - `functions/scripts/data/j2Teams.js`
    - `functions/scripts/data/j3Teams.js`
  - J2 / J3 の confirmed teams は意図的に空
  - data-only season membership scaffold 追加済み
    - `functions/scripts/data/competitionSeasonMemberships.js`
  - review docs 追加済み
    - `docs/current-j2-team-master-review.md`
    - `docs/current-j3-team-master-review.md`
  - promotion / relegation policy は維持
    - stable club identity は `/teams/{id}` に維持する
    - division membership は separate season membership data として扱う
    - promoted / relegated clubs は J1 / J2 / J3 間で同じ internal team ID を reuse する
    - division ごとの duplicate club docs は作成しない
  - dry-run validation は PASS
    - `node functions/scripts/seedCompetitionTeams.js football_j2 --dry-run`
    - `node functions/scripts/verifyCompetitionTeams.js football_j2 --dry-run`
    - `node functions/scripts/seedCompetitionTeams.js football_j3 --dry-run`
    - `node functions/scripts/verifyCompetitionTeams.js football_j3 --dry-run`
    - `npm --prefix functions run build`
    - `flutter analyze --no-pub`
- J2 / J3 official membership source review documented
  - commit: `0232f59 Document J2 J3 membership sources`
  - updated
    - `docs/current-j2-team-master-review.md`
    - `docs/current-j3-team-master-review.md`
  - added
    - `docs/current-j2-j3-season-membership-review.md`
  - official sources recorded
    - J.LEAGUE special page: https://www.jleague.jp/special/2026specialseason/j2-j3/
    - J.LEAGUE official standings: https://www.jleague.jp/standings/j2j3/
  - `明治安田Ｊ２・Ｊ３百年構想リーグ` を documented
  - four groups を documented
    - `EAST-A`
    - `EAST-B`
    - `WEST-A`
    - `WEST-B`
  - all membership rows remain `review`
  - internal team IDs remain `TBD`
  - API-SPORTS team IDs remain `TBD`
  - logo URLs remain `TBD`
  - seedable remains `no`
  - this is season / tournament membership evidence only, not stable team master seed data
  - `j2Teams.js` / `j3Teams.js` は empty and unchanged
  - no Firestore write / API-SPORTS call / deploy / service account or API key changes
- J2 / J3 stable internal team ID mapping review documented
  - commit: `8d7c960 Document J2 J3 stable ID mapping review`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
    - `docs/current-j2-team-master-review.md`
    - `docs/current-j3-team-master-review.md`
  - total membership rows reviewed: 40
  - matched to existing confirmed J1 stable team IDs: 0
  - unresolved rows requiring stable identity review: 40
  - existing team IDs reused: none
  - every membership row remains `review`
  - every internal team ID remains `TBD`
  - every `externalTeamId` remains `TBD`
  - every `logoUrl` remains `TBD`
  - every `seedable` remains `no`
  - rows are marked as `new-stable-id-candidate-needed; membership evidence only`
  - `j2Teams.js` / `j3Teams.js` は empty and unchanged
  - no source code / seed data / Firestore write / API call / deploy / serviceAccountKey or API key changes
- minimal `competitionSeasonKey` / tournament profile foundation 実装済み
  - commit: `32e7c99 Add J1 competition season foundation`
  - `functions/scripts/data/competitionSeasons.js` 追加済み
  - current J1 profile: `football_j1_2026_hyakunen`
  - `seedJ1SampleGame.js` は `competitionSeasonKey` を write する
  - `verifyJ1SampleGame.js` は `competitionSeasonKey` を required field として verify する
  - Flutter `Game` model は optional `competitionSeasonKey` を backward compatible に read/write する
  - actual `node functions/scripts/seedJ1SampleGame.js` により 4 J1 sample games を再write済み
  - actual `node functions/scripts/verifyJ1SampleGame.js` は PASS
  - multi-follow home-screen query check は PASS
  - `flutter analyze --no-pub` は `No issues found!`
  - validation 後の `git status --short` は clean
- explicit API season handling for football sync 実装済み
  - commit: `6274e7c Use competition season profile for football sync`
  - `functions/src/config/competitionSeasons.ts` 追加済み
  - generated `functions/lib/config/competitionSeasons.js` 追加済み
  - `syncFootball.ts` は API season に `new Date().getFullYear()` を使用しない
  - sync は `competitionKey` / legacy `sportKey` と `externalLeagueId` / legacy `rapidApiId` から competition season profile を解決する
  - fixture fetch は `seasonProfile.externalLeagueId` と `seasonProfile.apiSeason` を使用する
  - current J1 profile は `apiAccessibleOnCurrentPlan: false` のため、API-SPORTS を呼ばずに skip する
  - `fixtureToGameDoc()` は `competitionKey` / `competitionSeasonKey` / legacy `sportKey` / `externalFixtureId` / legacy `rapidApiFixtureId` を write する
  - `GameDoc` type は optional `competitionSeasonKey` に対応済み
  - `npm --prefix functions run build` は PASS
  - `flutter analyze --no-pub` は `No issues found!`
  - `rg` scan で `functions/src` の current-year API season assumption は検出されていない
- syncFootball converter parity / `football_adapter.ts` usage 実装済み
  - commit: `eb3f9e2 Use football adapter for sync game conversion`
  - `syncFootball.ts` は inline fixture-to-`GameDoc` conversion を持たない
  - `syncFootball.ts` は `functions/src/adapters/football_adapter.ts` の `adaptFootballFixtureToGameDoc()` を呼ぶ
  - adapter は `competitionSeasonKey` を受け取る
  - adapter-produced `GameDoc` は `competitionKey` / `competitionSeasonKey` / legacy `sportKey` / `leagueId` / home-away team IDs / Japanese names / English names / logo URLs / `startTimeUTC` / `startTimeJST` / `timezone` / `status` / `venue` / scores / `broadcastPlatforms` / `externalFixtureId` / legacy `rapidApiFixtureId` を含む
  - `npm --prefix functions run build` は PASS
  - `flutter analyze --no-pub` は `No issues found!`
  - `rg` scan で新規 API key usage や sync-path current-year season logic は検出されていない
- strict API team ID → internal team ID mapping 実装済み
  - commit: `b7bd99c Use strict football team ID mapping`
  - `syncFootball.ts` は seeded Firestore team docs から `teamByExternalId` を構築する
  - mapping は `externalTeamId` を優先し、legacy `rapidApiId` に fallback する
  - API-SPORTS home / away team IDs は `GameDoc` build 前に既知の internal `/teams/{id}` docs へ解決される必要がある
  - `football_team_{id}` placeholder fallback は sync path から削除済み
  - unmapped fixture は placeholder team ID で write せず、skip する
  - unmapped fixture warning は fixture ID、missing side、API team ID、API team name を含む
  - `npm --prefix functions run build` は PASS
  - `flutter analyze --no-pub` は `No issues found!`
  - `rg` scan で `functions/src` / `functions/scripts` / `lib` に `football_team_` は検出されていない
- football status mapping verification 実装済み
  - commit: `eea5078 Add football status mapping verification`
  - `functions/scripts/verifyFootballStatusMapping.js` 追加済み
  - API-SPORTS football status short code mapping を verify 済み
    - `TBD`, `NS` → `scheduled`
    - `1H`, `HT`, `2H`, `ET`, `BT`, `P`, `SUSP`, `INT`, `LIVE` → `live`
    - `FT`, `AET`, `PEN` → `finished`
    - `PST` → `postponed`
    - `CANC`, `ABD`, `AWD`, `WO` → `cancelled`
    - unknown fallback → `scheduled`
  - `mapFootballStatus()` の source change は不要
  - `npm --prefix functions run build` は PASS
  - `node functions/scripts/verifyFootballStatusMapping.js` は PASS
  - `flutter analyze --no-pub` は `No issues found!`
- football real game data verification script 実装済み
  - commit: `ed48905 Add football real game verification`
  - `functions/scripts/verifyFootballRealGames.js` 追加済み
  - script は read-only
  - dry-run は Firebase Admin SDK を initialize せず、Firestore read/write もしない
  - non-dry mode は Firestore read のみ
  - default target は `competitionKey: football_j1` / `competitionSeasonKey: football_j1_2026_hyakunen`
  - real sync docs は document ID が `football_` で始まる docs として扱う
  - non-real / sample docs はそれ以外として情報表示のみ行う
  - required field checks / team mapping checks / fixture ID compatibility checks は real sync docs のみに適用する
  - real sync docs が 0件の場合、default では warning + exit 0
  - `--require-games` では real sync docs 0件を failure とする
  - required `GameDoc` fields を verify する
  - `competitionKey === sportKey` を verify する
  - `externalFixtureId === rapidApiFixtureId` を verify する
  - supported `status` を verify する
  - home / away team IDs が `/teams` に存在することを verify する
  - team docs の competition key と external team ID を verify する
  - placeholder-like `football_team_` team IDs がないことを verify する
  - Home query shape を `homeTeamId` / `awayTeamId` `in`、`startTimeUTC >= now`、`orderBy startTimeUTC` で verify する
  - `npm --prefix functions run build` は PASS
  - `node functions/scripts/verifyFootballRealGames.js --dry-run` は PASS
  - `flutter analyze --no-pub` は `No issues found!`
- app-side team search 修正済み
  - `lib/data/repositories/team_repository.dart`
  - `lib/data/providers/team_providers.dart`
  - `lib/presentation/screens/team_search_screen.dart`
  - `G大阪` → ガンバ大阪 OK
  - `C大阪` → セレッソ大阪 OK
  - `ガンバ大阪` → ガンバ大阪 OK
  - `セレッソ大阪` → セレッソ大阪 OK
  - `東京V` → 東京ヴェルディ OK
  - `横浜FM` → 横浜Ｆ・マリノス OK
  - empty `Jリーグ` tab → 20 teams OK
- multiple team follow / unfollow は manual UI confirmation 済み
- Home screen behavior は J1 sample games 条件で確認済み
  - G大阪 / C大阪 follow → Osaka derby が表示される
  - 横浜FM / 東京V follow → Yokohama F・Marinos vs Tokyo Verdy が表示される
  - 福岡 / 広島 follow → Avispa Fukuoka vs Sanfrecce Hiroshima が表示される
  - 鹿島 / 浦和 follow → Kashima Antlers vs Urawa Reds が表示される
  - 関連チームを unfollow すると該当 game は Home から消える
  - follow team が 0件の場合、Home は followed-team empty state を表示する
  - follow / home logic は現時点で broken ではない
- followed teams / My Teams summary UI 実装済み
  - commit: `167d9d7 Add followed teams summary to home`
  - Home に compact `フォロー中のチーム` section を追加済み
  - followed team logo / nameJa / nameEn を表示
  - upcoming games がない followed team も My Teams に表示される
  - followed teams が存在し games が空の場合、My Teams を表示しつつ `直近の試合はありません` を表示
  - follow team が 0件の場合、既存の `フォローしているチームがありません` empty state を維持
  - G大阪 / C大阪 follow → My Teams に両方表示され、Osaka derby も表示される
  - 片方を unfollow → My Teams から消え、game behavior は正常
  - sample game がない team を follow → My Teams に表示される
  - 全 team unfollow → existing empty state に戻る
- API-SPORTS J1 team candidates inspection 済み
  - 2026 / 2025 teams endpoint は `Count: 0`
  - 2024 teams endpoint は 20 teams を返すが、current master としては採用しない
- `flutter analyze --no-pub` は `No issues found!`

未完了理由:

- Firebase Spark plan では Functions deploy ができず、Blaze plan が必要

現時点の active next tasks:

- Perform stable identity review for 40 unresolved J2 / J3 clubs
- Decide stable internal team ID candidates only after identity review
- Verify API-SPORTS team IDs and logo URLs separately
- Keep `j2Teams.js` and `j3Teams.js` empty until stable identity + API / logo verification is complete

後回し:

- Firestore write
- non-dry seed
- API-SPORTS sync
- deploy
- service account / API key work
- Blaze 化判断
- `getCalendar` deploy
- curl による `.ics` 実 URL 確認
- Cloud Functions / API-SPORTS sync

---

## Firebase Dependency Points

| 依存箇所 | 用途 | Firebase サービス |
|---|---|---|
| `main.dart` | アプリ起動時の初期化 | Firebase Core |
| `user_repository.dart` | 認証状態監視・ユーザープロフィール CRUD | Firebase Auth + Firestore |
| `team_repository.dart` | リーグ・チームデータ読み取り | Firestore |
| `game_repository.dart` | 試合データ読み取り（リアルタイム含む） | Firestore |
| `auth_providers.dart` | 認証状態の Riverpod Provider | Firebase Auth |
| `sign_in_screen.dart` | Google / Apple サインイン | Firebase Auth |
| `ics_url_builder.dart` | Cloud Functions の URL 生成 | Cloud Functions (URL のみ) |
| `game.dart` モデル | `Timestamp` 型の使用 | Firestore SDK |
| `user_profile.dart` モデル | `Timestamp` 型の使用 | Firestore SDK |
| `calendar_subscription.dart` モデル | ICS URL が Cloud Functions エンドポイントを指す | Cloud Functions |
| `functions/getCalendar.ts` | ユーザープロフィール・試合データ読み取り | Firestore (Admin SDK) |
| `functions/syncFootball.ts` | リーグ・チーム・試合データ書き込み | Firestore (Admin SDK) |
| `firestore.rules` | アクセス制御 | Firestore Security Rules |

---

## Candidate Responsibilities to Move to AWS

| 責務 | 現在の実装 | AWS 候補 |
|---|---|---|
| 試合データ同期パイプライン | Cloud Functions (Scheduled) + API-SPORTS | AWS Lambda + EventBridge Scheduler |
| .ics ファイル生成・配信 | Cloud Functions (HTTPS) | AWS Lambda + API Gateway または CloudFront |
| チームデータ・試合データのストレージ | Firestore | Amazon DynamoDB または RDS |
| 翻訳マップのストレージ | Firestore (`translationMaps`) | DynamoDB または S3 (JSON) |
| 放送プラットフォーム情報の管理 | 未実装 | DynamoDB |
| 全文検索 | Firestore prefix match（限定的） | Amazon OpenSearch Service |

**注意**: 認証（Firebase Auth）は現状 Flutter SDK と密結合しており、AWS Cognito への移行は Flutter 側の大規模改修を伴う。

---

## Data Model Gaps

### `Game` モデルの不足フィールド

| 不足フィールド | 現状 | 影響 |
|---|---|---|
| `homeTeamLogoUrl` / `awayTeamLogoUrl` | `Game` model / J1 sample games / `football_adapter.ts` は対応済み | `GameCard` ではまだロゴを表示していない。詳細は `docs/team-game-model-gaps.md` を参照 |
| `competitionRound` / `matchday` | なし | 「第○節」「ラウンド16」等の表示不可 |
| `broadcastPlatforms` の実データ | 常に空配列 | 放送情報が一切表示されない |
| `isNeutralVenue` | なし | 中立地開催の判定不可 |

### `Team` モデルの不足フィールド

| 不足フィールド | 現状 | 影響 |
|---|---|---|
| `stadium` / `homeVenue` | なし（`Game.venue` はあるが `Team` にはない） | チームのホームスタジアム情報なし |
| `division` / `conference` | なし | リーグ内の部門分けが表現できない |
| `foundedYear` / `description` | なし | チーム詳細画面に情報が少ない |

### `UserProfile` モデルの不足フィールド

| 不足フィールド | 現状 | 影響 |
|---|---|---|
| `favoriteTeamId`（メインチーム） | なし（`followedTeamIds` のみ） | 「お気に入り」と「フォロー」の区別なし |
| `notificationSettings` | なし | プッシュ通知設定不可 |

---

## Recommended Next 5 Tasks

優先順（Spark plan のまま Flutter + Firestore seed data で進める）：

### Task 1: Stable identity review for 40 unresolved J2 / J3 clubs
- `docs/current-j2-j3-season-membership-review.md` の 40 unresolved clubs を stable identity review する
- stable internal team ID candidates は identity review 後にのみ決める
- duplicate club docs を作らない
- `j2Teams.js` / `j3Teams.js` は stable identity + API / logo verification が揃うまで empty のまま維持する

### Task 2: API / logo verification for J2 / J3 stable identities
- API-SPORTS team ID / logo URL は separate lookup / verify 後にのみ seedable data にする
- stable identity + API / logo verification が揃うまで `j2Teams.js` / `j3Teams.js` は empty のまま維持する
- season membership は stable team IDs confirmed 後に separate data として追加する
- Firestore write / non-dry seed / API sync / deploy は行わない

### Task 3: 他 competition への generic pipeline 展開
- Premier League / LaLiga / Serie A / Bundesliga / Ligue 1 / UEFA competitions などの team master data scaffold を検討する
- competition ごとの data module を `competitionRegistry.js` に追加する
- league-specific な season / tournament membership は team master と分離して扱う

### Task 4: in-app followed-team calendar idea
- followed teams の試合だけを表示する in-app calendar view を検討する
- external `.ics` delivery とは別の Flutter UI task として扱う
- Home と同じ followed-team game query behavior を再利用する

### Task 5: Flutter UI polish / regression check / deferred backend work
- J1 team search / follow / unfollow / home sample-game behavior / My Teams summary は確認済み
- 今後 real game data を追加した後に主要検索語と follow 表示を再確認する
- Firestore write / non-dry seed / API-SPORTS sync / deploy / service account work は後回し
- Blaze 化判断
- `getCalendar` deploy / curl による `.ics` 実 URL確認
- API-SPORTS sync の deploy・動作確認

---

## Analyze Status (as of 2026-05-08)

```
error:   0
warning/info: 0
```

`flutter analyze --no-pub` は `No issues found!`。
