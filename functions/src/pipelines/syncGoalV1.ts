import * as admin from "firebase-admin";
import { GameDoc } from "../types";
import { GoalApiClient } from "../providers/goal/goalApiClient";
import { orchestrateGoalTeamFixtures, GoalFixtureSource, GoalSkipReason, TeamNames } from "../providers/goal/syncOrchestrator";
import { V1_GOAL_MEMBERSHIP_BINDINGS } from "../providers/goal/v1CompetitionBindings";

export const GOAL_WRITE_CHUNK_SIZE = 400;
export const V1_GOAL_TARGETS = Object.freeze(["kawasaki_frontale", "arsenal"] as const);

export function stableGoalGameId(sourceFixtureId: string): string {
  if (!sourceFixtureId) throw new Error("GOAL source fixture ID is required");
  return `goal_${Buffer.from(sourceFixtureId, "utf8").toString("base64url")}`;
}

export interface GoalSyncSummary {
  targets: number;
  providerFixturesFetched: number;
  gamesUpserted: number;
  gamesDeleted: number;
  duplicates: number;
  skipCounts: Partial<Record<GoalSkipReason, number>>;
  providerAnomalies: number;
}

interface WriteBatchLike {
  set(ref: admin.firestore.DocumentReference, data: GameDoc, options: { merge: true }): unknown;
  delete(ref: admin.firestore.DocumentReference): unknown;
  commit(): Promise<unknown>;
}

export interface GoalPersistence {
  gameRef(id: string): admin.firestore.DocumentReference;
  newBatch(): WriteBatchLike;
}

function firestorePersistence(db: admin.firestore.Firestore): GoalPersistence {
  return { gameRef: id => db.collection("games").doc(id), newBatch: () => db.batch() };
}

type PendingWrite = { kind: "set"; id: string; game: GameDoc } | { kind: "delete"; id: string };

/** Each chunk obtains and commits a fresh batch; committed batches are never reused. */
export async function persistGoalWrites(
  persistence: GoalPersistence,
  writes: readonly PendingWrite[],
  chunkSize = GOAL_WRITE_CHUNK_SIZE
): Promise<void> {
  if (!Number.isInteger(chunkSize) || chunkSize < 1 || chunkSize > 499) throw new Error("Invalid write chunk size");
  for (let offset = 0; offset < writes.length; offset += chunkSize) {
    const batch = persistence.newBatch();
    for (const write of writes.slice(offset, offset + chunkSize)) {
      const ref = persistence.gameRef(write.id);
      if (write.kind === "set") batch.set(ref, write.game, { merge: true });
      else batch.delete(ref);
    }
    await batch.commit();
  }
}

export interface SyncGoalOptions {
  source?: GoalFixtureSource;
  persistence?: GoalPersistence;
  names?: TeamNames;
  now?: () => Date;
  targets?: readonly string[];
}

/** Centralized provider fetch, normalization, deterministic de-duplication and reconciliation. */
export async function syncGoalV1Fixtures(apiKey: string, options: SyncGoalOptions = {}): Promise<GoalSyncSummary> {
  const source = options.source ?? new GoalApiClient(apiKey);
  const persistence = options.persistence ?? firestorePersistence(admin.firestore());
  const names = options.names ?? { nameJa: (id: string) => id };
  const targets = options.targets ?? V1_GOAL_TARGETS;
  const games = new Map<string, GameDoc>();
  const unsupported = new Set<string>();
  const skipCounts: Partial<Record<GoalSkipReason, number>> = {};
  let fetched = 0;
  let duplicates = 0;

  for (const target of targets) {
    const countingSource: GoalFixtureSource = { fixtures: async teamId => {
      const fixtures = await source.fixtures(teamId); fetched += fixtures.length; return fixtures;
    } };
    const result = await orchestrateGoalTeamFixtures(countingSource, target,
      V1_GOAL_MEMBERSHIP_BINDINGS, names, options.now);
    for (const skipped of result.skipped) {
      skipCounts[skipped.reason] = (skipCounts[skipped.reason] ?? 0) + 1;
      // Unsupported active-binding state retracts a formerly published event. Anomalies preserve it.
      if (skipped.reason === "unsupported_status") {
        const id = stableGoalGameId(skipped.fixtureId);
        if (games.has(id)) throw new Error(`Conflicting supported/unsupported GOAL fixture: ${skipped.fixtureId}`);
        unsupported.add(id);
      }
    }
    for (const game of result.games) {
      const id = stableGoalGameId(game.sourceFixtureId!);
      const previous = games.get(id);
      if (unsupported.has(id)) throw new Error(`Conflicting supported/unsupported GOAL fixture: ${game.sourceFixtureId}`);
      if (previous) {
        duplicates += 1;
        if (gameSignature(previous) !== gameSignature(game)) {
          throw new Error(`Conflicting GOAL fixture returned by target feeds: ${game.sourceFixtureId}`);
        }
      } else games.set(id, game);
    }
  }
  const writes: PendingWrite[] = [
    ...[...games].sort(([a], [b]) => a.localeCompare(b)).map(([id, game]) => ({ kind: "set" as const, id, game })),
    ...[...unsupported].sort().map(id => ({ kind: "delete" as const, id })),
  ];
  await persistGoalWrites(persistence, writes);
  const summary: GoalSyncSummary = { targets: targets.length, providerFixturesFetched: fetched,
    gamesUpserted: games.size, gamesDeleted: unsupported.size, duplicates, skipCounts,
    providerAnomalies: skipCounts.provider_data_anomaly ?? 0 };
  console.info("GOAL V1 sync complete", summary);
  return summary;
}

function gameSignature(game: GameDoc): string {
  return JSON.stringify({ ...game, startTimeUTC: game.startTimeUTC.toMillis() });
}
