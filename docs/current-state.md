# Current State — sports_calendar_sync

> Generated: 2026-04-21  
> Based on: code inspection of all source files in `lib/` and `functions/src/`  
> Build status: `flutter pub get` ✅ / `flutter build apk --debug` ✅ / `flutter build web` ✅

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
| Google サインイン | Implemented in code | `sign_in_screen.dart` |
| Apple サインイン | Implemented in code | `sign_in_screen.dart` |
| サインアウト | Implemented in code | `settings_screen.dart` |
| ユーザープロフィール作成（初回サインイン時） | Defined but not verified | `sign_in_screen.dart`, `user_repository.dart` |
| ホーム画面（フォロー中チームの試合一覧） | Blocked by data/config | `home_screen.dart` |
| チーム検索（スポーツ種別タブ + テキスト検索） | Blocked by data/config | `team_search_screen.dart` |
| チーム詳細（試合一覧 + フォロー/解除） | Blocked by data/config | `team_detail_screen.dart` |
| チームフォロー / アンフォロー | Defined but not verified | `user_repository.dart` |
| 設定画面（アカウント情報 / 言語切替 / サインアウト） | Defined but not verified | `settings_screen.dart` |
| iCalendar URL 生成 | Implemented in code | `ics_url_builder.dart` |
| iCalendar URL シェアシート（コピー / Google Calendar / Apple Calendar） | Defined but not verified | `ics_share_sheet.dart` |
| 試合カード表示（日時 / チーム名 / スコア / 会場 / 放送） | Blocked by data/config | `game_card.dart` |
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
| `getCalendar` (HTTPS) — .ics ファイル生成・配信 | Defined but not verified | `functions/getCalendar.ts` |
| `scheduledSyncFootball` — 6時間ごとにサッカー試合データ同期 | Blocked by data/config | `index.ts`, `syncFootball.ts` |
| `triggerFootballSync` — 手動トリガー（HTTPS Callable） | Defined but not verified | `index.ts` |
| API-SPORTS → Firestore パイプライン（サッカー） | Blocked by data/config | `syncFootball.ts` |
| タイムゾーン正規化（UTC Timestamp + JST 文字列） | Implemented in code | `utils/timezone.ts` |
| チーム名翻訳マップ（英語 → 日本語） | Implemented in code | `utils/translation.ts` |
| 野球 / バスケ / アメフト / ラグビーの同期パイプライン | Missing / incomplete | — |
| 放送プラットフォーム情報の自動取得 | Missing / incomplete | `broadcastPlatforms` は常に空配列 |
| Google Calendar API 連携（自動追加） | Missing / incomplete | フィールドのみ定義 |

---

## Why the App Does Not Show Useful Data Yet

アプリはビルド・起動できるが、実際のデータが表示されない理由を切り分ける。

### 1. Missing Firestore Seed Data

`leagues` / `teams` コレクションにデータが一切投入されていない。

- チーム検索画面は「リーグが見つかりませんでした」と表示される
- `syncFootball.ts` は `leagues` コレクションを読んでリーグ一覧を取得するため、シードデータがないと同期も動かない
- **必要な作業**: `leagues` / `teams` コレクションに少なくとも 1 リーグ分のデータを手動または スクリプトで投入する

### 2. Missing API Secret / Key Setup

API-SPORTS キーが Firebase Functions の設定に存在しない。

- `scheduledSyncFootball` は起動時に `functions.config().apisports?.key` を確認し、未設定なら即 return する
- **必要な作業**: `firebase functions:config:set apisports.key=YOUR_KEY` を実行してデプロイし直す

### 3. Missing Synced Game Data

上記 1・2 の結果として `games` コレクションにデータが存在しない。

- ホーム画面の試合一覧は常に空
- `getCalendar` Cloud Function は `games` を読むため、.ics ファイルも空になる
- **必要な作業**: 1・2 を解決後、`triggerFootballSync` を手動呼び出しして `games` にデータが入ることを確認する

### 4. Unverified Function Execution Path

Cloud Functions のデプロイ状況・実行ログが未確認。

- `getCalendar` / `scheduledSyncFootball` / `triggerFootballSync` がデプロイ済みかどうか不明
- Firebase Console または `firebase functions:list` で確認が必要
- `triggerFootballSync` を Flutter アプリまたは curl から呼び出してエンドツーエンドで動作確認が取れていない

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
| `homeTeamLogoUrl` / `awayTeamLogoUrl` | なし（`Team.logoUrl` を別途取得が必要） | `GameCard` でロゴを表示するには追加クエリが必要 |
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

優先順（データ経路の確立を最優先とする）：

### Task 1: Firestore シードデータ投入（leagues / teams）
- `leagues` / `teams` コレクションに少なくとも J1 リーグ + 所属チームのデータを投入する
- `syncFootball.ts` が `leagues` を読んで動くための前提条件
- 手動投入または Node.js スクリプトで実施

### Task 2: API-SPORTS キーの設定
- `firebase functions:config:set apisports.key=YOUR_KEY` を実行
- Functions を再デプロイして設定が反映されることを確認

### Task 3: `triggerFootballSync` のエンドツーエンド動作確認
- Task 1・2 完了後、`triggerFootballSync` を手動呼び出し
- Firebase Console で `games` コレクションにデータが書き込まれることを確認
- エラーログがあれば `syncFootball.ts` のデバッグを行う

### Task 4: 実データでのホーム / 検索 / チーム詳細画面の動作確認
- Task 3 完了後、アプリを実機または Chrome で起動
- チーム検索 → フォロー → ホーム画面に試合が表示されることを確認
- `getCalendar` Cloud Function が正しい .ics を返すことを確認

### Task 5: `Game` モデルへの不足フィールド定義
- `homeTeamLogoUrl` / `awayTeamLogoUrl` の追加（`GameCard` でのロゴ表示に必要）
- `competitionRound` / `matchday` の追加（試合の文脈情報）
- ホーム / アウェイの区別を UI で表現するためのフィールド整理
- `syncFootball.ts` の `fixtureToGameDoc` にフィールドを追加する

---

## Analyze Status (as of 2026-04-21)

```
error:   0
warning: 1  — ics_share_sheet.dart:150 未使用変数 `theme`
info:    3  — deprecated API (withOpacity, Share.share)
```

これらはアプリの動作に影響しない。Task 4 完了後に修正する。
