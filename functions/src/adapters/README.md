# functions/src/adapters/

## 目的

外部 API レスポンス → Firestore ドメインモデル（`GameDoc` 等）への変換を担う **adapter 層**。

## 設計方針

- 外部 API のレスポンス型（`RapidApiFootballFixture` 等）をそのままドメインモデルに持ち込まない
- API 仕様変更時の影響範囲をこのディレクトリ内に限定する
- `syncFootball.ts` 等のパイプラインは adapter を呼び出すだけにする

## Phase 0 の状態

| ファイル | 状態 | 説明 |
|---|---|---|
| `football_adapter.ts` | ✅ 作成済み（placeholder） | API-SPORTS football → GameDoc |

## Phase 1 以降の予定

- `syncFootball.ts` の `fixtureToGameDoc` 関数を `football_adapter.ts` に移動する
- 野球・バスケ等の adapter を追加する
- adapter の入力型を `RawApiResponse` として抽象化し、データソース差し替えに対応する

## データソース差し替えの考え方

```
API-SPORTS football API
  └─ RapidApiFootballFixture (raw)
       └─ football_adapter.ts (変換)
            └─ GameDoc (domain)
                 └─ Firestore games/{id}

将来: TheSportsDB / MLB Stats API 等
  └─ TheSportsDbFixture (raw)
       └─ thesportsdb_football_adapter.ts (変換)
            └─ GameDoc (domain) ← 同じ型
                 └─ Firestore games/{id}
```

adapter 層を挟むことで、データソースを差し替えても `GameDoc` 以降のコードは変更不要になる。
# GOAL V1 boundary

`goalFootballAdapter.ts` accepts only lifecycle values enumerated by the GOAL
status policy; unknown values are explicit orchestration skips and never
default to scheduled.

The score boundary follows the official GOAL SDK fixture examples confirmed for
this quality pass: `homeScore` and `awayScore` are nullable numeric fixture
properties. The checked-in `/teams/:id/fixtures` capture predates completed
results and contains neither property, which is treated as unavailable rather
than as a zero. At runtime each value must be a non-negative integer or
null/absent. Numeric values must be present as a pair; malformed or asymmetric
numeric data rejects the provider response. The adapter persists both values
only when both are numeric, preserving `0-0`, and otherwise omits both fields.
