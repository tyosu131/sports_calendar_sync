# Phase 0 — Current Architecture

> Generated: 2026-04-29  
> Purpose: コード構造の観点から責務を整理し、Phase 0 の改善方針を明確にする

---

## ディレクトリ構成

```
sports_calendar_sync/
├── lib/
│   ├── main.dart                        # Firebase 初期化 / MaterialApp.router
│   ├── firebase_options.dart            # FlutterFire 自動生成
│   ├── core/
│   │   └── utils/
│   │       ├── app_constants.dart       # Firestore コレクション名 / API URL 定数
│   │       ├── app_router.dart          # GoRouter 定義（5画面）
│   │       ├── date_time_utils.dart     # UTC→JST 変換・フォーマット
│   │       └── ics_url_builder.dart     # Cloud Functions ICS URL 生成
│   ├── domain/
│   │   └── models/
│   │       ├── sport.dart               # SportType enum + League クラス
│   │       ├── team.dart                # Team クラス
│   │       ├── game.dart                # Game / GameStatus / BroadcastInfo
│   │       ├── user_profile.dart        # UserProfile クラス
│   │       └── calendar_subscription.dart # CalendarSubscription クラス
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── team_repository.dart     # Firestore leagues / teams 読み取り
│   │   │   ├── game_repository.dart     # Firestore games 読み取り
│   │   │   └── user_repository.dart     # Firestore users CRUD + Firebase Auth
│   │   └── providers/
│   │       ├── repository_providers.dart # Repository の Riverpod Provider
│   │       ├── auth_providers.dart       # Auth 状態 / UserProfile Stream
│   │       ├── team_providers.dart       # League / Team / Search providers
│   │       └── game_providers.dart       # Game providers
│   └── presentation/
│       ├── screens/
│       │   ├── home_screen.dart          # フォロー中チームの試合一覧
│       │   ├── team_search_screen.dart   # スポーツタブ + チーム検索
│       │   ├── team_detail_screen.dart   # チーム詳細 + 試合一覧
│       │   ├── settings_screen.dart      # アカウント / ICS URL / 言語
│       │   └── sign_in_screen.dart       # Google / Apple サインイン
│       └── widgets/
│           ├── game_card.dart            # 試合カード（日時 / チーム / スコア）
│           ├── team_list_tile.dart       # チームリストタイル + フォローボタン
│           └── ics_share_sheet.dart      # ICS URL シェアシート
└── functions/src/
    ├── index.ts                          # Cloud Functions エントリポイント
    ├── types.ts                          # Firestore ドキュメント型 / API レスポンス型
    ├── functions/
    │   └── getCalendar.ts               # HTTPS Function: .ics ファイル生成
    ├── pipelines/
    │   └── syncFootball.ts              # サッカー試合データ同期パイプライン
    └── utils/
        ├── timezone.ts                  # UTC→JST 変換 / ステータスマッピング
        └── translation.ts              # Firestore 翻訳マップ読み取り
```

---

## 責務マップ

### Flutter アプリ側

| 層 | ファイル | 責務 | 問題点 |
|---|---|---|---|
| **UI / 画面** | `home_screen.dart` | フォロー中チームの試合フィード | — |
| **UI / 画面** | `team_search_screen.dart` | スポーツタブ + チーム検索 | `SportType.values` を直接イテレートしており、スポーツ追加時に enum 変更が必要 |
| **UI / 画面** | `team_detail_screen.dart` | チーム詳細 + 試合一覧 | — |
| **UI / 画面** | `settings_screen.dart` | アカウント / ICS URL / 言語 | — |
| **UI / 画面** | `sign_in_screen.dart` | Google / Apple サインイン | Firebase Auth に直接依存 |
| **UI / Widget** | `game_card.dart` | 試合カード表示 | `homeTeamLogoUrl` / `awayTeamLogoUrl` によるロゴ表示対応済み。実データ側の logo population は継続確認 |
| **UI / Widget** | `team_list_tile.dart` | チームリスト行 | — |
| **UI / Widget** | `ics_share_sheet.dart` | ICS URL シェア | Cloud Functions URL をハードコード |
| **State** | `auth_providers.dart` | Firebase Auth 状態 / UserProfile Stream | Firebase 直結 |
| **State** | `team_providers.dart` | League / Team / Search | `SportType?` を引数に取る（enum 依存） |
| **State** | `game_providers.dart` | Game providers | — |
| **Repository** | `team_repository.dart` | Firestore leagues / teams | Firestore 直結 |
| **Repository** | `game_repository.dart` | Firestore games | Firestore 直結 |
| **Repository** | `user_repository.dart` | Firestore users + Firebase Auth | Firebase 二重依存 |
| **Domain Model** | `sport.dart` | `SportType` enum + `League` | enum にスポーツ一覧がベタ書き。追加時に switch 文を全修正 |
| **Domain Model** | `team.dart` | `Team` | `SportType` enum 依存 |
| **Domain Model** | `game.dart` | `Game` | `sportKey` フィールドなし（サッカー専用に見える） |
| **Domain Model** | `user_profile.dart` | `UserProfile` | `followedTeamIds: List<String>` のみ（スポーツ別管理不可） |
| **Domain Model** | `calendar_subscription.dart` | `CalendarSubscription` | Cloud Functions URL 前提 |
| **Utils** | `app_constants.dart` | 定数 | `rapidApiFootballBase` 等の API URL が Flutter 側に存在（未使用） |
| **Utils** | `app_router.dart` | GoRouter | — |
| **Utils** | `date_time_utils.dart` | UTC→JST 変換 | — |
| **Utils** | `ics_url_builder.dart` | ICS URL 生成 | Cloud Functions URL をハードコード |

### Cloud Functions 側

| ファイル | 責務 | 問題点 |
|---|---|---|
| `index.ts` | Functions エントリポイント | `functions.config()` 廃止予定 API 使用 |
| `types.ts` | Firestore / API 型定義 | `SportType` が 5 種類のみ（8 競技に未対応） |
| `getCalendar.ts` | .ics ファイル生成 | `followedTeamIds` のみ参照（スポーツ別未対応） |
| `syncFootball.ts` | サッカー試合同期 | API レスポンスをそのまま変換（adapter 層なし） |
| `utils/timezone.ts` | UTC→JST / ステータスマッピング | サッカー・野球のみ対応 |
| `utils/translation.ts` | 翻訳マップ読み取り | Firestore 依存（将来 DynamoDB 等に移行困難） |

---

## 現在の問題点（Phase 0 で解決すべき）

### 1. スポーツ一覧がコードに埋め込まれている

```dart
// team_search_screen.dart — 問題のある箇所
_tabController = TabController(
  length: SportType.values.length + 1,  // enum に依存
  vsync: this,
);
// ...
...SportType.values.map((s) => Tab(text: s.displayNameJa)),  // enum を直接イテレート
```

- `SportType` enum を変更するたびに、switch 文・UI・テストが全て影響を受ける
- 「有効/無効」「表示順」「将来のデータソース」を管理できない

### 2. Game モデルに `sportKey` がない

```dart
// game.dart — 現状
class Game {
  final String leagueId;
  final String homeTeamNameJa;
  // sportKey がない → どの競技の試合か判別不可
  // homeTeamLogoUrl / awayTeamLogoUrl は追加済み
}
```

### 3. UserProfile がスポーツ別チーム管理に対応していない

```dart
// user_profile.dart — 現状
final List<String> followedTeamIds;  // 全スポーツ混在
// selectedSports がない
// favoriteTeamIdsBySport がない
```

### 4. API レスポンスとドメインモデルの境界がない

```typescript
// syncFootball.ts — 問題のある箇所
// RapidApiFootballFixture を直接 GameDoc に変換している
// adapter / mapper 層がなく、API 変更時の影響範囲が大きい
```

### 5. Firebase 依存が全層に散在している

- `UserRepository` が `FirebaseFirestore` と `FirebaseAuth` を両方持つ
- `UserProfile.fromFirestore()` が Firestore の `Timestamp` 型に直接依存
- `Game.fromFirestore()` が Firestore の `Timestamp` 型に直接依存
- Repository 層に interface がなく、テスト・差し替えが困難

---

## Phase 0 で整備する構造

```
lib/
├── core/
│   ├── config/
│   │   └── sports_registry.dart    # [NEW] 8 競技の registry（追加・削除・並び替え対応）
│   └── utils/
│       └── (既存ファイル維持)
├── domain/
│   └── models/
│       ├── sport_definition.dart   # [NEW] SportDefinition クラス（registry エントリ）
│       ├── sport.dart              # [MODIFIED] SportType enum は維持しつつ registry に委譲
│       ├── game.dart               # [MODIFIED] sportKey / homeTeamLogoUrl 追加
│       ├── team.dart               # [MODIFIED] sportKey を String に変更（enum 非依存）
│       ├── user_profile.dart       # [MODIFIED] selectedSports / favoriteTeamIdsBySport 追加
│       └── (その他維持)
└── (その他維持)

functions/src/
├── adapters/                       # [NEW] API レスポンス → ドメイン変換の境界
│   ├── football_adapter.ts         # API-SPORTS football → GameDoc
│   └── README.md                   # adapter 層の設計方針
├── domain/                         # [NEW] Functions 側ドメイン型（Firestore 非依存）
│   └── sport_registry.ts           # Functions 側スポーツ registry
└── (既存ファイル維持)
```

---

## 外部依存関係図

```
Flutter App
  ├── Firebase Auth (sign_in_screen, user_repository, auth_providers)
  ├── Cloud Firestore (team_repository, game_repository, user_repository)
  └── Cloud Functions (ics_url_builder → getCalendar URL)

Cloud Functions
  ├── Firebase Admin SDK (Firestore read/write)
  ├── API-SPORTS (syncFootball → fixtures API)
  └── ical-generator (getCalendar → .ics 生成)
```

---

## Free MVP / Cost-Control Mode

2026-06 時点では、Blaze upgrade / Firebase Functions deploy / API sync を意図的に deferred し、無料範囲で画面価値を確認できる Free MVP mode を優先している。

### 起動方法

```bash
flutter run --dart-define=USE_SAMPLE_DATA=true
```

### Repository 切り替え

`repository_providers.dart` は `const bool.fromEnvironment('USE_SAMPLE_DATA')` を使って repository 実装を切り替える。

| mode | Team | Game | User |
|---|---|---|---|
| normal | `FirestoreTeamRepository` | `FirestoreGameRepository` | `FirestoreUserRepository` |
| sample | `SampleTeamRepository` | `SampleGameRepository` | `SampleUserRepository` |

sample mode では Firestore read/write を行わず、follow / unfollow は in-memory state で処理する。

### Sample data scope

- football sample teams / games
- NPB sample teams / games
- NBA sample teams / games
- past finished games with score
- future scheduled games

### ScheduleScreen

`ScheduleScreen` は `/schedule` route で表示される競技非依存の in-app schedule UI。

- Home AppBar から遷移できる
- followed teams の games を JST 日付単位で月間表示する
- date cell 内に試合概要を表示する
- 日付押下時のみ selected date details を表示する
- external `.ics` delivery とは別の Flutter UI として扱う

### Logo asset strategy

Free MVP では Team Search / Home / TeamDetail / Schedule / GameCard の logo display は実装済み。

現時点では外部 `logoUrl` と fallback 表示を併用する。小さいロゴは外部画像ソース、縮小描画、Flutter Web rendering の影響で roughness が残るが、Free MVP では許容する。

短期方針:

- 誤ロゴを出さない
- fallback が崩れない
- 十分視認できることを優先する
- NPB は安定 URL がないため fallback を維持する
- high-resolution logo 改善 / SVG 対応 / local asset 管理は今すぐ実装しない
- 新規 package は追加しない

将来検討:

- high-resolution logo source verification
- SVG support strategy
- local asset management
- logo source rights / license / usage policy review
- fallback policy
- team master data と logo asset metadata の関係整理
- API-SPORTS logo URL / official source / local asset の優先順位
- cache / CDN / asset bundle の検討

sample mode では Home / TeamDetail の iCalendar sync icon を非表示にし、未デプロイの Cloud Functions URL をユーザーに見せない。

---

## 参照: 既存 docs

- `docs/current-state.md` — 機能ステータス一覧
- `docs/e2e-minimum-setup.md` — E2E セットアップ手順
- `docs/phase0-boundaries.md` — Firebase / AWS 責務境界（本 Phase 0 で作成）
