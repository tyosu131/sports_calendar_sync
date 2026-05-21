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
- J2 / J3 stable identity candidate review documented
  - commit: `1d4f505 Document J2 J3 stable identity candidates`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
    - `docs/current-j2-team-master-review.md`
    - `docs/current-j3-team-master-review.md`
  - documentation-only candidate internal team IDs proposed: 40
  - confirmed internal team IDs: 0
  - API-SPORTS IDs verified: 0
  - logo URLs verified: 0
  - seedable rows: 0
  - existing membership rows still keep
    - `internal team id: TBD`
    - `externalTeamId: TBD`
    - `logoUrl: TBD`
    - `seedable: no`
  - candidate IDs are review candidates only
  - candidate IDs are not confirmed `/teams/{id}` documents
  - candidate IDs are not seed data
  - `j2Teams.js` / `j3Teams.js` は empty and unchanged
  - no source code / seed data / Firestore write / API call / deploy / serviceAccountKey or API key changes
- J2 / J3 candidate name verification completed
  - commit: `1137b69 Verify J2 J3 stable identity candidate names`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - Total candidate IDs reviewed: 40
  - Candidate IDs kept unchanged: 40
  - Candidate IDs changed: 0
  - Candidate IDs requiring further review: 0
  - Confirmed internal IDs: 0
  - API-SPORTS IDs verified: 0
  - Logo URLs verified: 0
  - Seedable rows: 0
  - candidate name verification は完了済み
  - API-SPORTS team ID / logo URL は separate verification が必要
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 API-SPORTS team ID / logo URL verification plan documented
  - commit: `ff5f33f Document J2 J3 API logo verification plan`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - documentation-only で追加済み
    - `API-SPORTS Team ID / Logo URL Verification Plan`
    - 40件分の `API-SPORTS Verification Tracker`
  - tracker status は全件 `not-started`
  - `externalTeamId` は全件 `TBD`
  - `logoUrl` は全件 `TBD`
  - `seedable` は全件 `no`
  - API-SPORTS API call は未実行
  - API lookup / API request は承認後に理由と exact command を提示してから実行する方針
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 API-SPORTS team ID / logo URL read-only lookup script 追加済み
  - commit: `3d5a5fe Add Japan football API lookup script`
  - added
    - `functions/scripts/fetchJapanFootballTeamsFromApiSports.js`
  - read-only inspection 専用
  - `API_SPORTS_KEY` env のみ使用
  - stdout のみに出力
  - Firebase Admin SDK 初期化なし
  - Firestore read/write なし
  - serviceAccountKey 読み取りなし
  - ファイル出力なし
  - 対応引数
    - `--leagues --season <year>`
    - `--league <id> --season <year>`
    - `--search <name>`
    - `--json`
  - `node --check functions/scripts/fetchJapanFootballTeamsFromApiSports.js` は PASS
  - 実 API-SPORTS API call は未実行
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 API-SPORTS lookup evidence documented
  - commit: `36d2b4b Record J2 J3 API lookup evidence`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - API-SPORTS league discovery succeeded for Japan / 2024
  - J1 League externalLeagueId: 98
  - J2 League externalLeagueId: 99
  - J3 League externalLeagueId: 100
  - Japan Football League externalLeagueId: 497
  - Candidate rows with API evidence found: 40
  - Direct / near-direct evidence rows: 29
  - Name variance review rows: 11
  - API-SPORTS IDs verified enough for documentation evidence: 40
  - Logo URLs found: 40
  - Rows ready for seed data: 0
  - `seedable` は全件 `no`
  - `api-lookup-name-variance-review` rows は seedable 前に review が必要
  - tracker rows are API lookup evidence only
  - confirmed `/teams/{id}` documents ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 API name variance review documented
  - commit: `37cb071 Document J2 J3 API name variance review`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Name Variance Review` section 追加済み
  - 11件の `api-lookup-name-variance-review` rows を documentation-only で整理済み
  - Rows acceptable as API evidence candidates: 10
  - Rows requiring stronger rebrand / continuity review before seedable: 1
  - `reilac_shiga` / `Biwako Shiga` は seedable 前に強めの continuity review が必要な高注意行
  - Rows moved to seedable: 0
  - Confirmed `/teams/{id}` documents created: 0
  - `j2Teams.js` / `j3Teams.js` entries added: 0
  - `seedable` は全件 `no`
  - Firestore write / non-dry seed / API sync / deploy は実行していない
- J2 / J3 confirmed team module criteria documented
  - commit: `09ad557 Document J2 J3 confirmed team criteria`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Confirmed Team Module Criteria` section 追加済み
  - confirmed entry 化の条件を documentation-only で整理済み
  - Confirmed entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` / `Biwako Shiga` は continuity review 完了まで confirmed entry 候補にしない方針
  - tracker と name variance review は evidence であり、seedable master data ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Reilac Shiga continuity review documented
  - commit: `9466b40 Document Reilac Shiga continuity review`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Reilac Shiga Continuity Review` section 追加済み
  - `Reilac Shiga FC` / `レイラック滋賀FC` を current official-facing name として扱う
  - `Biwako Shiga` を API-SPORTS raw / older-name evidence として扱う
  - API-SPORTS externalTeamId: `7117`
  - logoUrl: `https://media.api-sports.io/football/teams/7117.png`
  - lookup source: `JFL 2024 / 497`
  - Continuity approval completed: no
  - Confirmed entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` は continuity approval 未完了のため、引き続き seedable / confirmed entry から除外
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 per-club confirmed entry approval flow documented
  - commit: `c6f73f8 Document J2 J3 per-club approval flow`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Confirmed Entry Approval Flow` section 追加済み
  - club row 単位で承認する方針
  - bulk approval はしない
  - direct / near-direct 29件は `approval-ready` candidates
  - name variance rows excluding `reilac_shiga`: 10件は `approval-ready-after-variance-review` candidates
  - `reilac_shiga`: `approval-blocked-continuity`
  - Clubs approved for module entry: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 per-club approval batch 1 documented
  - commit: `ad59b42 Document J2 J3 approval batch 1`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Batch 1` section 追加済み
  - Batch 1 candidates listed: 5
  - 対象
    - `vegalta_sendai`
    - `shonan_bellmare`
    - `blaublitz_akita`
    - `yokohama_fc`
    - `montedio_yamagata`
  - variance status: 全件 `direct-or-near-direct`
  - recommended approval state: 全件 `approval-ready`
  - approval decision: 全件 `not-approved-yet`
  - Batch 1 candidates approved for module entry: 0
  - `reilac_shiga` included: no
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - confirmed entries はまだ作らない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Vegalta Sendai per-club approval decision review documented
  - commit: `a4146e1 Review Vegalta Sendai approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - vegalta_sendai` section 追加済み
  - Reviewed club: `vegalta_sendai`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 1 table changed: no
  - `vegalta_sendai` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Shonan Bellmare per-club approval decision review documented
  - commit: `6b836d0 Review Shonan Bellmare approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - shonan_bellmare` section 追加済み
  - Reviewed club: `shonan_bellmare`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 1 table changed: no
  - `shonan_bellmare` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - lookup source `J1 2024 / 98` は stable club identity の API evidence であり、2026 J2/J3 special competition membership や permanent division membership を意味しない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Blaublitz Akita per-club approval decision review documented
  - commit: `ad73ee4 Review Blaublitz Akita approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - blaublitz_akita` section 追加済み
  - Reviewed club: `blaublitz_akita`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 1 table changed: no
  - `blaublitz_akita` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - lookup source `J2 2024 / 99` は stable club identity の API evidence であり、2026 J2/J3 special competition membership や permanent division membership を意味しない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Yokohama FC per-club approval decision review documented
  - commit: `cceed69 Review Yokohama FC approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - yokohama_fc` section 追加済み
  - Reviewed club: `yokohama_fc`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 1 table changed: no
  - `yokohama_fc` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - lookup source `J2 2024 / 99` は stable club identity の API evidence であり、2026 J2/J3 special competition membership や permanent division membership を意味しない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Montedio Yamagata per-club approval decision review documented
  - commit: `f2df696 Review Montedio Yamagata approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - montedio_yamagata` section 追加済み
  - Reviewed club: `montedio_yamagata`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 1 table changed: no
  - Batch 1 individual reviews completed: 5 / 5
  - Batch 1 の5件はすべて docs-only で `approved-for-module-entry-candidate` まで review 済み
    - `vegalta_sendai`
    - `shonan_bellmare`
    - `blaublitz_akita`
    - `yokohama_fc`
    - `montedio_yamagata`
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Batch 1 actual module entry preparation review documented
  - commit: `6b8db23 Document J2 J3 batch 1 module preparation`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Batch 1 Actual Module Entry Preparation Review` section 追加済み
  - Batch 1 reviewed candidates: 5
  - Batch 1 ready for separate module entry approval: 5
  - 対象
    - `vegalta_sendai`
    - `shonan_bellmare`
    - `blaublitz_akita`
    - `yokohama_fc`
    - `montedio_yamagata`
  - per-club review status: 全件 `approved-for-module-entry-candidate`
  - module entry preparation status: 全件 `ready-for-separate-module-entry-approval`
  - target module candidate: 全件 `j2Teams.js` candidate
  - Actual module entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 created: no
  - `reilac_shiga` included: no
  - docs-only の準備レビューであり、actual `approved-for-module-entry` file entry ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Batch 1 j2Teams.js exact diff plan documented
  - commit: `26edc71 Document J2 J3 batch 1 j2Teams diff plan`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Batch 1 j2Teams.js Exact Diff Plan` section 追加済み
  - Planned target file: `functions/scripts/data/j2Teams.js`
  - Planned entries: 5
  - 対象
    - `vegalta_sendai`
    - `shonan_bellmare`
    - `blaublitz_akita`
    - `yokohama_fc`
    - `montedio_yamagata`
  - implementation status: 全件 `planned-not-written`
  - Actual module entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` included: no
  - docs-only の exact diff plan であり、actual `j2Teams.js` file change ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 Batch 1 actual team module entries added
  - commit: `9546bde Add J2 batch 1 team entries`
  - updated
    - `functions/scripts/data/j2Teams.js`
  - Actual `j2Teams.js` entries added: 5
  - 追加済み entries
    - `vegalta_sendai`
    - `shonan_bellmare`
    - `blaublitz_akita`
    - `yokohama_fc`
    - `montedio_yamagata`
  - Batch 1 の5件は docs-only planned から actual `j2Teams.js` module entries に進んだ
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - non-dry seed: 0
  - API calls: 0
  - deploy: 0
  - `reilac_shiga` included: no
  - validation
    - `node --check functions/scripts/data/j2Teams.js` PASS
    - `node functions/scripts/seedCompetitionTeams.js football_j2 --dry-run` は confirmed teams: 5 / Firestore will not be written
    - `node functions/scripts/verifyCompetitionTeams.js football_j2 --dry-run` は all 5 team shapes valid / In-memory team master checks PASSED
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- J2 / J3 per-club approval batch 2 documented
  - commit: `79ee857 Document J2 J3 approval batch 2`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Batch 2` section 追加済み
  - Batch 2 candidates listed: 5
  - 対象
    - `tochigi_city`
    - `tochigi_sc`
    - `vanraure_hachinohe`
    - `ventforet_kofu`
    - `fujieda_myfc`
  - recommended approval state: 全件 `approval-ready`
  - approval decision: 全件 `not-approved-yet`
  - Actual module entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` included: no
  - Batch 1 entries changed: no
  - Batch 2 は docs-only の candidate list であり、actual module entry ではない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Tochigi City per-club approval decision review documented
  - commit: `3f58c59 Review Tochigi City approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - tochigi_city` section 追加済み
  - Reviewed club: `tochigi_city`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 table changed: no
  - Batch 2 individual reviews completed: 1 / 5
  - `tochigi_city` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Tochigi SC per-club approval decision review documented
  - commit: `0c1b521 Review Tochigi SC approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - tochigi_sc` section 追加済み
  - Reviewed club: `tochigi_sc`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 table changed: no
  - Batch 2 individual reviews completed: 2 / 5
  - `tochigi_sc` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Vanraure Hachinohe per-club approval decision review documented
  - commit: `984ad56 Review Vanraure Hachinohe approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - vanraure_hachinohe` section 追加済み
  - Reviewed club: `vanraure_hachinohe`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 table changed: no
  - Batch 2 individual reviews completed: 3 / 5
  - `vanraure_hachinohe` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - `vanraure_hachinohe` は `j3Teams.js` candidate だが、actual `j3Teams.js` entry はまだ作らない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Ventforet Kofu per-club approval decision review documented
  - commit: `e27815f Review Ventforet Kofu approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - ventforet_kofu` section 追加済み
  - Reviewed club: `ventforet_kofu`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 table changed: no
  - Batch 2 individual reviews completed: 4 / 5
  - `ventforet_kofu` は docs-only で module entry candidate として前進しただけ
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Fujieda MYFC per-club approval decision review documented
  - commit: `f27a90c Review Fujieda MYFC approval decision`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Per-Club Approval Decision Review - fujieda_myfc` section 追加済み
  - Reviewed club: `fujieda_myfc`
  - Review result: `approved-for-module-entry-candidate`
  - Actual module entry added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - Batch 2 table changed: no
  - Batch 2 individual reviews completed: 5 / 5
  - `fujieda_myfc` は docs-only で module entry candidate として前進しただけ
  - Batch 2 の5件はすべて docs-only で `approved-for-module-entry-candidate` まで review 済み
    - `tochigi_city`
    - `tochigi_sc`
    - `vanraure_hachinohe`
    - `ventforet_kofu`
    - `fujieda_myfc`
  - actual `approved-for-module-entry` file change ではない
  - `j2Teams.js` / `j3Teams.js` は unchanged
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Batch 2 actual module entry preparation review documented
  - commit: `e54ff0a Document J2 J3 batch 2 module preparation`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Batch 2 Actual Module Entry Preparation Review` section 追加済み
  - Batch 2 reviewed candidates: 5
  - Batch 2 ready for separate module entry approval: 5
  - 対象
    - `tochigi_city`
    - `tochigi_sc`
    - `vanraure_hachinohe`
    - `ventforet_kofu`
    - `fujieda_myfc`
  - per-club review status: 全件 `approved-for-module-entry-candidate`
  - module entry preparation status: 全件 `ready-for-separate-module-entry-approval`
  - target module candidate
    - `tochigi_city`: `j2Teams.js` candidate
    - `tochigi_sc`: `j2Teams.js` candidate
    - `vanraure_hachinohe`: `j3Teams.js` candidate
    - `ventforet_kofu`: `j2Teams.js` candidate
    - `fujieda_myfc`: `j2Teams.js` candidate
  - `vanraure_hachinohe` だけが Batch 2 の `j3Teams.js` candidate
  - 他4件は Batch 2 の `j2Teams.js` candidate
  - Actual module entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` included: no
  - Batch 3 created: no
  - docs-only の準備レビューであり、actual `approved-for-module-entry` file entry ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
- Batch 2 j2Teams.js / j3Teams.js exact diff plan documented
  - commit: `8c34858 Document J2 J3 batch 2 exact diff plan`
  - updated
    - `docs/current-j2-j3-season-membership-review.md`
  - `Batch 2 j2Teams.js / j3Teams.js Exact Diff Plan` section 追加済み
  - Planned target files
    - `functions/scripts/data/j2Teams.js`
    - `functions/scripts/data/j3Teams.js`
  - Planned `j2Teams.js` entries: 4
    - `tochigi_city`
    - `tochigi_sc`
    - `ventforet_kofu`
    - `fujieda_myfc`
  - Planned `j3Teams.js` entries: 1
    - `vanraure_hachinohe`
  - `vanraure_hachinohe` だけが Batch 2 の `j3Teams.js` planned entry
  - implementation status: all rows `planned-not-written`
  - Actual module entries added: 0
  - `j2Teams.js` entries added: 0
  - `j3Teams.js` entries added: 0
  - Firestore writes: 0
  - Seedable rows changed: 0
  - `reilac_shiga` included: no
  - docs-only の exact diff plan であり、actual `j2Teams.js` / `j3Teams.js` file change ではない
  - `j2Teams.js` / `j3Teams.js` への投入はまだ不要
  - Firestore write / non-dry seed / API sync / deploy は引き続き deferred
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

- Batch 1 の5件は actual `j2Teams.js` module entries 追加後の docs 更新まで完了
- Batch 2 の5件はすべて docs-only `approved-for-module-entry-candidate` まで review 済み
- Batch 2 の5件はすべて `ready-for-separate-module-entry-approval` まで preparation review 済み
- `tochigi_city` / `tochigi_sc` / `ventforet_kofu` / `fujieda_myfc` は `j2Teams.js` candidate
- `vanraure_hachinohe` は `j3Teams.js` candidate
- Batch 2 exact diff plan は docs-only で追加済み
- Planned `j2Teams.js` entries: 4 (`tochigi_city`, `tochigi_sc`, `ventforet_kofu`, `fujieda_myfc`)
- Planned `j3Teams.js` entries: 1 (`vanraure_hachinohe`)
- Next decision point: Batch 2 actual module entries を追加するかどうか別承認で判断する
- actual 追加に進む場合も `j2Teams.js` 4件と `j3Teams.js` 1件を分けて変更する
- `tochigi_city` / `tochigi_sc` / `vanraure_hachinohe` / `ventforet_kofu` / `fujieda_myfc` は actual module file entry ではない
- まだ actual `j2Teams.js` / `j3Teams.js` entries は追加しない
- `vanraure_hachinohe` は `j3Teams.js` candidate だが、actual `j3Teams.js` entry はまだ作らない
- Do not use bulk approval for Batch 1 or future batches
- Keep `reilac_shiga` / `Biwako Shiga` excluded from seedable / confirmed entry candidates until continuity approval is completed
- Do not add more confirmed entries while preparing future per-club approval decisions
- Keep candidate internal team IDs as documentation-only review candidates until stable identity + API evidence + logo evidence are approved together
- Do not create confirmed `/teams/{id}` documents, add `j3Teams.js` entries, or add additional `j2Teams.js` entries yet
- Keep Firestore write / non-dry seed / API sync / deploy deferred

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

### Task 1: API / logo verification for J2 / J3 stable identities
- `docs/current-j2-j3-season-membership-review.md` に 40件分の API-SPORTS lookup evidence は記録済み
- `api-lookup-name-variance-review` の 11件は documentation-only review として整理済み
- `reilac_shiga` / `Biwako Shiga` continuity review は documentation-only で記録済みだが、continuity approval は未完了
- `reilac_shiga` は continuity approval 完了まで seedable / confirmed entry から除外する
- API-SPORTS team ID / logo URL evidence は documentation evidence であり、confirmed `/teams/{id}` documents ではない
- stable identity + API evidence + logo evidence が承認されるまで `j2Teams.js` / `j3Teams.js` は empty のまま維持する
- season membership は stable team IDs confirmed 後に separate data として追加する
- Firestore write / non-dry seed / API sync / deploy は行わない

### Task 2: Confirmed J2 / J3 team module preparation
- confirmed team module criteria は documentation-only で整理済み
- per-club confirmed entry approval flow は documentation-only で整理済み
- Batch 1 の5件は `approval-ready` / `not-approved-yet` として documentation-only で整理済み
- `vegalta_sendai` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `shonan_bellmare` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `blaublitz_akita` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `yokohama_fc` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `montedio_yamagata` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- Batch 1 individual reviews completed: 5 / 5
- Batch 1 actual module entry preparation review documented
- Batch 1 ready for separate module entry approval: 5
- target module candidate: 全件 `j2Teams.js` candidate
- Batch 1 `j2Teams.js` exact diff plan documented
- Planned target file: `functions/scripts/data/j2Teams.js`
- Planned entries: 5
- implementation status: 全件 `planned-not-written`
- Batch 1 actual `j2Teams.js` module entries added: 5
- `vegalta_sendai` / `shonan_bellmare` / `blaublitz_akita` / `yokohama_fc` / `montedio_yamagata` は actual `j2Teams.js` module entries に追加済み
- `node --check functions/scripts/data/j2Teams.js` PASS
- `node functions/scripts/seedCompetitionTeams.js football_j2 --dry-run` は confirmed teams: 5 / Firestore will not be written
- `node functions/scripts/verifyCompetitionTeams.js football_j2 --dry-run` は all 5 team shapes valid / In-memory team master checks PASSED
- Batch 2 docs-only candidate list documented
- Batch 2 candidates listed: 5
- Batch 2 対象: `tochigi_city`, `tochigi_sc`, `vanraure_hachinohe`, `ventforet_kofu`, `fujieda_myfc`
- Batch 2 recommended approval state: 全件 `approval-ready`
- Batch 2 approval decision: 全件 `not-approved-yet`
- 次は Batch 2 の候補を1件ずつ approval decision review する
- `tochigi_city` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `tochigi_sc` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `vanraure_hachinohe` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `ventforet_kofu` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- `fujieda_myfc` は docs-only で `approved-for-module-entry-candidate` まで review 済み
- Batch 2 individual reviews completed: 5 / 5
- Batch 2 の5件はすべて docs-only で `approved-for-module-entry-candidate` まで review 済み
- `tochigi_city` / `tochigi_sc` / `vanraure_hachinohe` / `ventforet_kofu` / `fujieda_myfc` は actual module file entry ではない
- `vanraure_hachinohe` は `j3Teams.js` candidate だが、actual `j3Teams.js` entry はまだ作らない
- Batch 2 actual module entry preparation review documented
- Batch 2 ready for separate module entry approval: 5
- `tochigi_city` / `tochigi_sc` / `ventforet_kofu` / `fujieda_myfc` は `j2Teams.js` candidate
- `vanraure_hachinohe` だけが `j3Teams.js` candidate
- Batch 2 exact diff plan documented
- Planned `j2Teams.js` entries: 4
  - `tochigi_city`
  - `tochigi_sc`
  - `ventforet_kofu`
  - `fujieda_myfc`
- Planned `j3Teams.js` entries: 1
  - `vanraure_hachinohe`
- implementation status: all rows `planned-not-written`
- 次は Batch 2 actual module entries を追加するかどうか別承認で判断する
- actual 追加に進む場合も `j2Teams.js` 4件と `j3Teams.js` 1件を分けて変更する
- まだ actual `j2Teams.js` / `j3Teams.js` entries は追加しない
- bulk approval は行わない
- `reilac_shiga` / `Biwako Shiga` は continuity review 完了まで confirmed entry 候補にしない
- stable identity + API / logo verification が承認済みの club のみ `j2Teams.js` / `j3Teams.js` への confirmed entry 候補にする
- candidate IDs は confirmed `/teams/{id}` documents ではなく、seed data でもない状態を維持する
- 追加の `j2Teams.js` / `j3Teams.js` への投入、Firestore write、non-dry seed は別 approval まで行わない

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
