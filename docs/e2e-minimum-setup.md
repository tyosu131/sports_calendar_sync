# E2E Minimum Setup Guide

> 目的: Firestore に最小データを入れ、Cloud Functions を 1 回走らせ、アプリに実データが出るところまで確認する  
> 前提: Firebase CLI ログイン済み (`firebase login:list` で `tyosu131@gmail.com` が表示されること)  
> プロジェクト ID: `sports-calendar-sync-a4564`

---

## 現在の状態（確認済み）

| 項目 | 状態 |
|---|---|
| Firebase CLI ログイン | ✅ `tyosu131@gmail.com` |
| Firebase プロジェクト | ✅ `sports-calendar-sync-a4564` |
| Functions TypeScript ビルド | ✅ `functions/lib/` 生成済み |
| Cloud Functions API (GCP) | ❌ **未有効化** — 403 エラー |
| Firestore API (GCP) | ❌ **未有効化** — 403 エラー |
| Cloud Functions デプロイ | ❌ **未デプロイ** — `getCalendar` が 404 |
| `functions.config().apisports.key` | ❌ **未設定** — `{}` |
| `leagues` コレクション | ❌ **データなし** |
| `teams` コレクション | ❌ **データなし** |
| `games` コレクション | ❌ **データなし** |
| `firebase.json` の Functions/Firestore 設定 | ❌ **Flutter のみ** — deploy 設定なし |
| `.firebaserc` | ❌ **存在しない** |

---

## Free MVP sample mode（推奨の最初の確認）

Blaze upgrade / Firebase Functions deploy / API sync / Firestore seed を行う前に、無料範囲で画面価値を確認する場合は sample mode を使う。

```bash
flutter pub get
flutter run --dart-define=USE_SAMPLE_DATA=true
```

sample mode では以下を確認できる。

- Team Search
- Home followed-team summary
- TeamDetail
- Schedule (`/schedule`)
- follow / unfollow in memory
- football / NPB / NBA sample games
- finished game score display

sample mode では Firestore read/write、Cloud Functions、API-SPORTS sync、Secret Manager / `API_SPORTS_KEY` を使わない。Home / TeamDetail の iCalendar sync actions も非表示にする。

この E2E guide の以降の Firebase / Cloud Functions 手順は、paid deployment path のための deferred work として扱う。

---

## Step 0: 前提条件の確認

```bash
# Firebase CLI バージョン確認
firebase --version  # 15.8.0 以上

# ログイン確認
firebase login:list  # tyosu131@gmail.com が表示されること

# Node.js バージョン確認（Functions は Node 20 が必要）
node --version  # v20.x.x 推奨（現在 v25.8.0 — 動作するが非推奨）
```

---

## Step 1: GCP API の有効化（ブラウザ操作が必要）

以下の 2 つの API を Firebase Console / GCP Console で有効化する。  
**これは CLI では実行できない。ブラウザで手動操作が必要。**

### 1-1. Cloud Functions API を有効化

```
https://console.developers.google.com/apis/api/cloudfunctions.googleapis.com/overview?project=sports-calendar-sync-a4564
```

→ 「有効にする」ボタンをクリック

### 1-2. Cloud Firestore API を有効化

```
https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=sports-calendar-sync-a4564
```

→ 「有効にする」ボタンをクリック

### 1-3. Firestore データベースの作成

Firebase Console で Firestore データベースを作成する（まだ存在しない場合）：

```
https://console.firebase.google.com/project/sports-calendar-sync-a4564/firestore
```

→ 「データベースを作成」→ **本番環境モード** → リージョン: `asia-northeast1`

---

## Step 2: firebase.json と .firebaserc の整備

現在の `firebase.json` は Flutter 設定のみで、Functions / Firestore のデプロイ設定がない。  
以下の内容で `firebase.json` を更新し、`.firebaserc` を新規作成する。

### 2-1. firebase.json の更新

`sports_calendar_sync/firebase.json` を以下に置き換える：

```json
{
  "functions": [
    {
      "source": "../functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules"
  },
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "sports-calendar-sync-a4564",
          "appId": "1:1070492584469:android:53a28feb534909c42d9c1c",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "ios": {
        "default": {
          "projectId": "sports-calendar-sync-a4564",
          "appId": "1:1070492584469:ios:5b1f8ce3497accb42d9c1c",
          "uploadDebugSymbols": false,
          "fileOutput": "ios/Runner/GoogleService-Info.plist"
        }
      },
      "macos": {
        "default": {
          "projectId": "sports-calendar-sync-a4564",
          "appId": "1:1070492584469:ios:5b1f8ce3497accb42d9c1c",
          "uploadDebugSymbols": false,
          "fileOutput": "macos/Runner/GoogleService-Info.plist"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "sports-calendar-sync-a4564",
          "configurations": {
            "android": "1:1070492584469:android:53a28feb534909c42d9c1c",
            "ios": "1:1070492584469:ios:5b1f8ce3497accb42d9c1c",
            "macos": "1:1070492584469:ios:5b1f8ce3497accb42d9c1c",
            "web": "1:1070492584469:web:737fc437625067b52d9c1c",
            "windows": "1:1070492584469:web:8c1cfae889ff08f92d9c1c"
          }
        }
      }
    }
  }
}
```

### 2-2. .firebaserc の新規作成

`sports_calendar_sync/.firebaserc` を新規作成：

```json
{
  "projects": {
    "default": "sports-calendar-sync-a4564"
  }
}
```

---

## Step 3: Firestore シードデータの投入

### 必要な最小フィールド

#### `leagues` コレクション（ドキュメント ID: `j1_league`）

`syncFootball.ts` が読み取るフィールド：
- `sportType` (string): `"football"` — **必須**（`where("sportType", "==", "football")` でフィルタ）
- `rapidApiId` (number): API-SPORTS のリーグ ID — **必須**（`if (!leagueData.rapidApiId) continue;` でスキップ）
- `nameEn` (string): ログ出力に使用
- `nameJa` (string): 表示用

```json
{
  "nameEn": "J1 League",
  "nameJa": "J1リーグ",
  "sportType": "football",
  "country": "Japan",
  "rapidApiId": 98
}
```

> **API-SPORTS の J1 League ID**: `98`（API-Football v3 の league ID — 実測確認済み）

#### `teams` コレクション（ドキュメント ID: `kashima_antlers`）

`syncFootball.ts` が読み取るフィールド：
- `sportType` (string): `"football"` — **必須**（`where("sportType", "==", "football")` でフィルタ）
- `rapidApiId` (number): API-SPORTS のチーム ID — **必須**（`teamByRapidId` マップに登録）
- `nameJa` (string): 日本語チーム名（翻訳マップの代わりに使用）
- `leagueId` (string): 所属リーグのドキュメント ID

```json
{
  "nameEn": "Kashima Antlers",
  "nameJa": "鹿島アントラーズ",
  "leagueId": "j1_league",
  "sportType": "football",
  "country": "Japan",
  "rapidApiId": 290
}
```

> **API-SPORTS の鹿島アントラーズ ID**: `290`（league 98 / season 2024 所属確認済み）  
> ※ team code は重複があるため識別に使用しない。team id `290` を正とする。

#### `translationMaps` コレクション（ドキュメント ID: `football`）

`syncFootball.ts` が読み取るが、存在しなくても英語名にフォールバックするため **任意**。  
ただし日本語表示のために投入を推奨：

```json
{
  "teams": {
    "Kashima Antlers": "鹿島アントラーズ",
    "Urawa Red Diamonds": "浦和レッズ",
    "Gamba Osaka": "ガンバ大阪"
  },
  "leagues": {
    "J1 League": "J1リーグ"
  }
}
```

### 投入方法

**方法 A: Firebase Console（ブラウザ）**

```
https://console.firebase.google.com/project/sports-calendar-sync-a4564/firestore
```

1. 「コレクションを開始」→ コレクション ID: `leagues`
2. ドキュメント ID: `j1_league`、上記フィールドを入力
3. 同様に `teams` コレクションに `kashima_antlers` を追加

**方法 B: Firebase Admin SDK スクリプト（推奨）**

`functions/` ディレクトリで以下のスクリプトを実行：

```bash
cd /Users/User/sportsCalender/sports_calendar_sync/functions

# seed.js を一時作成して実行
node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // 要取得

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seed() {
  await db.collection('leagues').doc('j1_league').set({
    nameEn: 'J1 League',
    nameJa: 'J1リーグ',
    sportType: 'football',
    country: 'Japan',
    rapidApiId: 98
  });
  
  await db.collection('teams').doc('kashima_antlers').set({
    nameEn: 'Kashima Antlers',
    nameJa: '鹿島アントラーズ',
    leagueId: 'j1_league',
    sportType: 'football',
    country: 'Japan',
    rapidApiId: 290
  });
  
  await db.collection('translationMaps').doc('football').set({
    teams: { 'Kashima Antlers': '鹿島アントラーズ' },
    leagues: { 'J1 League': 'J1リーグ' }
  });
  
  console.log('Seed complete');
  process.exit(0);
}

seed().catch(console.error);
"
```

> **注意**: `serviceAccountKey.json` は Firebase Console → プロジェクト設定 → サービスアカウント → 「新しい秘密鍵の生成」で取得する。  
> このファイルは `.gitignore` に追加し、リポジトリにコミットしないこと。

---

## Step 4: API-SPORTS キーの設定

### 4-1. API-SPORTS キーの取得

1. https://dashboard.api-sports.io/ にアクセス（API-SPORTS 直契約）
2. アカウント登録・サブスクライブ（無料プランあり）
3. ダッシュボードから API キーをコピー

> **注意**: RapidAPI 経由ではなく **API-SPORTS 直契約** を使用する。  
> - Base URL: `https://v3.football.api-sports.io/`  
> - 認証ヘッダー: `x-apisports-key: YOUR_KEY`（`x-rapidapi-key` ではない）

### 4-2. キーの設定

> **重要**: `functions.config()` API は 2026 年 3 月に廃止予定。  
> 現在のコード (`index.ts`) は `functions.config().apisports?.key` を使用する前提に移行する。  
> 短期的には以下の旧 API で設定し、後で環境変数（params）に移行する。

```bash
cd /Users/User/sportsCalender/sports_calendar_sync

# 旧 API（現在のコードに対応）
firebase functions:config:set apisports.key="YOUR_APISPORTS_KEY" --project sports-calendar-sync-a4564
```

---

## Step 5: firebase.json の整備と Functions デプロイ

Step 2 で `firebase.json` と `.firebaserc` を更新した後：

```bash
cd /Users/User/sportsCalender/sports_calendar_sync/sports_calendar_sync

# Functions のビルド確認
cd ../functions && npm run build && cd ../sports_calendar_sync

# Firestore ルールのデプロイ
firebase deploy --only firestore:rules

# Functions のデプロイ（初回は時間がかかる）
firebase deploy --only functions
```

デプロイ成功の確認：

```bash
# getCalendar が 404 でなく 400 (uid missing) を返すことを確認
curl -s "https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar"
# 期待値: "Missing required query parameter: uid"
```

---

## Step 6: triggerFootballSync の実行

2 つの検証方法を使い分ける。

---

### 方法 A: Pipeline Verification（デプロイ不要・推奨）

> **目的**: Cloud Functions をデプロイせずに、パイプライン本体（`syncFootball.ts`）が正しく動くかを直接確認する。  
> Functions API の有効化・デプロイが完了していなくても実行できる。

```bash
cd /Users/User/sportsCalender/sports_calendar_sync/functions

node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// syncFootballFixtures を直接呼び出す（pipeline verification）
const { syncFootballFixtures } = require('./lib/pipelines/syncFootball');
syncFootballFixtures('YOUR_APISPORTS_KEY')
  .then(() => { console.log('Done'); process.exit(0); })
  .catch(e => { console.error(e); process.exit(1); });
"
```

---

### 方法 B: Deployed Function Verification

> **目的**: デプロイ済みの `triggerFootballSync` Cloud Function が本番環境で正しく動くかを確認する。  
> Step 5 のデプロイが完了していることが前提。

**B-1: Firebase Console から実行**

```
https://console.firebase.google.com/project/sports-calendar-sync-a4564/functions
```

→ `triggerFootballSync` → 「テスト」→ 空の JSON `{}` で実行

**B-2: curl から実行（HTTPS Callable）**

```bash
# Firebase ID トークンが必要（Flutter アプリでサインイン後に取得）
curl -X POST \
  "https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/triggerFootballSync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"data": {}}'
```

---

## Step 7: 成功判定チェックリスト

### Firestore データ確認

```
https://console.firebase.google.com/project/sports-calendar-sync-a4564/firestore
```

| チェック項目 | 確認方法 | 期待値 |
|---|---|---|
| `leagues` にデータがある | Firestore Console | `j1_league` ドキュメントが存在 |
| `teams` にデータがある | Firestore Console | `kashima_antlers` ドキュメントが存在 |
| `games` にデータが入った | Firestore Console | `football_XXXXXXX` 形式のドキュメントが複数存在 |

### Cloud Functions 確認

```bash
# getCalendar が動作することを確認（uid は Firestore に存在するユーザーの UID）
curl -s "https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar?uid=YOUR_UID"
# 期待値: BEGIN:VCALENDAR を含み、かつ VEVENT が 1 件以上存在すること
# 確認コマンド例:
curl -s "https://asia-northeast1-sports-calendar-sync-a4564.cloudfunctions.net/getCalendar?uid=YOUR_UID" | grep -c "BEGIN:VEVENT"
# → 1 以上の数値が返れば成功
```

> **注意**: `BEGIN:VCALENDAR` のみ返ってきても `VEVENT` が 0 件の場合は、  
> `games` コレクションにデータが存在しないか、ユーザーがチームをフォローしていない。

### Flutter アプリ確認

> **前提**: ホーム画面に試合が表示されるには、サインイン済みユーザーが  
> `users/{uid}.followedTeamIds` に少なくとも 1 チームの ID を持っている必要がある。  
> これは `user_repository.dart` の `followTeam()` を通じて書き込まれる。  
> チームをフォローせずにホーム画面を開いても試合は表示されない。

1. **チーム検索画面**: 「J1リーグ」タブを開くと「鹿島アントラーズ」が表示される
2. **フォロー操作**: 鹿島アントラーズをフォローする（`users/{uid}.followedTeamIds` に `kashima_antlers` が追加される）
3. **ホーム画面**: フォロー後、直近の試合カードが表示される（`games` コレクションに `homeTeamId` または `awayTeamId` が `kashima_antlers` のドキュメントが必要）
4. **チーム詳細画面**: 鹿島アントラーズの詳細画面に試合一覧が表示される
5. **ICS URL**: 設定画面またはホーム画面のカレンダーアイコンから URL が生成される

---

## 人手が必要な箇所（自動化不可）

| 作業 | 理由 | 対応方法 |
|---|---|---|
| Cloud Functions API の有効化 | GCP Console のブラウザ操作が必要 | Step 1-1 のリンクを開いて「有効にする」 |
| Firestore API の有効化 | GCP Console のブラウザ操作が必要 | Step 1-2 のリンクを開いて「有効にする」 |
| Firestore データベースの作成 | Firebase Console のブラウザ操作が必要 | Step 1-3 のリンクを開いて作成 |
| API-SPORTS キーの取得 | API-SPORTS アカウントが必要 | Step 4-1 を参照 |
| サービスアカウントキーの取得 | Firebase Console のブラウザ操作が必要 | Firebase Console → プロジェクト設定 → サービスアカウント |
| `triggerFootballSync` の初回実行 | Callable Function は認証済みユーザーが必要 | Step 6 の方法 A（Pipeline Verification）が最も簡単 |

---

## 追加メモ

### functions.config() の廃止について

現在の `index.ts` は廃止予定の `functions.config()` を使用している。  
2026 年 3 月以降はデプロイが失敗する可能性がある。  
短期的には旧 API で設定し、後で `defineSecret()` または環境変数ファイルに移行する。

```typescript
// 現在のコード（廃止予定）
const apiSportsKey = functions.config().apisports?.key;

// 移行後のコード（params API）
import { defineSecret } from "firebase-functions/params";
const apiSportsKey = defineSecret("APISPORTS_KEY");
```

### API-SPORTS 直契約の制限

API-Football（API-SPORTS 直契約）の無料プランは 1 日 100 リクエストまで。  
J1 リーグ 1 シーズン分のフィクスチャ取得で数十リクエストを消費する。  
初回テストは 1 リーグのみで実施することを推奨。

### Firestore インデックス

`game_repository.dart` は複合クエリ（`homeTeamId` + `startTimeUTC`）を使用している。  
初回クエリ時に Firestore がインデックス作成を要求するエラーが出る場合は、  
エラーメッセージ内の URL をブラウザで開いてインデックスを作成する。
