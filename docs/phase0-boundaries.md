# Phase 0 — Firebase / AWS 責務境界

> Generated: 2026-04-29  
> Purpose: Firebase と将来の AWS 移行を見据えた責務境界を定義する

---

## 現在の構成（Firebase Only）

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App                                                    │
│  ├── Firebase Auth  (認証)                                      │
│  ├── Cloud Firestore (データ読み取り)                            │
│  └── Cloud Functions URL (ICS 生成)                             │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  Firebase / GCP                                                 │
│  ├── Firebase Auth  (認証基盤)                                  │
│  ├── Cloud Firestore (メインデータストア)                        │
│  └── Cloud Functions (asia-northeast1)                          │
│       ├── getCalendar  (HTTPS: .ics 生成)                       │
│       └── syncFootball (Scheduled: 試合データ同期)              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  外部 API                                                       │
│  └── API-SPORTS (直契約)                                        │
│       Base URL: https://v3.football.api-sports.io/              │
│       Auth: x-apisports-key: {key}                              │
│       Config: functions.config().apisports.key                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Firebase の責務（現在・維持）

| サービス | 責務 | 変更予定 |
|---|---|---|
| **Firebase Auth** | ユーザー認証（Google / Apple） | なし |
| **Cloud Firestore** | leagues / teams / games / users / translationMaps | なし |
| **Cloud Functions** | ICS 生成 / 試合データ同期 | なし |

---

## API-SPORTS 直契約の設定

### 確定値（2026-04-29 実測確認済み）

| 項目 | 値 |
|---|---|
| J1 League league id | `98` |
| Kashima Antlers team id | `290` |
| Base URL | `https://v3.football.api-sports.io/` |
| Auth header | `x-apisports-key: {key}` |
| Firebase config key | `apisports.key` |

### Firebase Functions config 設定コマンド

```bash
# 設定
firebase functions:config:set apisports.key="YOUR_API_KEY"

# 確認
firebase functions:config:get

# ローカル開発用 .runtimeconfig.json
firebase functions:config:get > functions/.runtimeconfig.json
```

### syncFootball.ts での参照方法

```typescript
// 現在（旧 RapidAPI 前提 — 変更対象）
const apiKey = functions.config().rapidapi?.key;
const baseUrl = "https://v3.football.api-sports.io/";
const headers = {
  "x-rapidapi-key": apiKey,
  "x-rapidapi-host": "v3.football.api-sports.io",
};

// 変更後（API-SPORTS 直契約）
const apiKey = functions.config().apisports?.key;
const baseUrl = "https://v3.football.api-sports.io/";
const headers = {
  "x-apisports-key": apiKey,
};
```

---

## 将来の AWS 移行境界（Phase 2 以降の参考）

```
┌─────────────────────────────────────────────────────────────────┐
│  Firebase（維持）                                               │
│  ├── Firebase Auth  (認証基盤 — 変更コスト大のため維持)          │
│  └── Cloud Firestore (メインデータストア — 維持)                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  AWS（将来移行候補）                                            │
│  ├── Lambda (試合データ同期 — syncFootball の移行先)            │
│  ├── EventBridge (スケジューラ — Cloud Scheduler の代替)        │
│  └── Secrets Manager (API キー管理 — functions.config() の代替) │
└─────────────────────────────────────────────────────────────────┘
```

### 移行時の境界ルール

1. **Firebase Auth は維持**: Flutter SDK との統合コストが高いため
2. **Firestore は維持**: Flutter SDK との統合コストが高いため
3. **Cloud Functions → Lambda**: 試合データ同期パイプラインのみ移行候補
4. **adapter 層が境界**: `functions/src/adapters/` が Firebase / AWS の境界になる

---

## Phase 0 で整備した境界

### 1. API キー管理の統一

```
変更前: functions.config().rapidapi.key
変更後: functions.config().apisports.key
```

### 2. HTTP ヘッダーの統一

```
変更前: x-rapidapi-key / x-rapidapi-host (RapidAPI 経由)
変更後: x-apisports-key (API-SPORTS 直契約)
```

### 3. adapter 層の設置

```
functions/src/adapters/
├── football_adapter.ts  # API-SPORTS → GameDoc
└── README.md            # 設計方針
```

---

## 参照

- `docs/phase0-current-architecture.md` — 現在のアーキテクチャ詳細
- `docs/phase0-summary.md` — Phase 0 変更サマリー
- `docs/e2e-minimum-setup.md` — E2E セットアップ手順
