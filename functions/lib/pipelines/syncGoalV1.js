"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.V1_GOAL_TARGETS = exports.GOAL_WRITE_CHUNK_SIZE = void 0;
exports.stableGoalGameId = stableGoalGameId;
exports.persistGoalWrites = persistGoalWrites;
exports.syncGoalV1Fixtures = syncGoalV1Fixtures;
const admin = __importStar(require("firebase-admin"));
const goalApiClient_1 = require("../providers/goal/goalApiClient");
const syncOrchestrator_1 = require("../providers/goal/syncOrchestrator");
const v1CompetitionBindings_1 = require("../providers/goal/v1CompetitionBindings");
const teamIdentity_1 = require("../providers/goal/teamIdentity");
exports.GOAL_WRITE_CHUNK_SIZE = 400;
exports.V1_GOAL_TARGETS = Object.freeze(["kawasaki_frontale", "arsenal"]);
function stableGoalGameId(sourceFixtureId) {
    if (!sourceFixtureId)
        throw new Error("GOAL source fixture ID is required");
    return `goal_${Buffer.from(sourceFixtureId, "utf8").toString("base64url")}`;
}
function firestorePersistence(db) {
    return { gameRef: id => db.collection("games").doc(id), newBatch: () => db.batch() };
}
/** Each chunk obtains and commits a fresh batch; committed batches are never reused. */
async function persistGoalWrites(persistence, writes, chunkSize = exports.GOAL_WRITE_CHUNK_SIZE) {
    if (!Number.isInteger(chunkSize) || chunkSize < 1 || chunkSize > 499)
        throw new Error("Invalid write chunk size");
    for (let offset = 0; offset < writes.length; offset += chunkSize) {
        const batch = persistence.newBatch();
        for (const write of writes.slice(offset, offset + chunkSize)) {
            const ref = persistence.gameRef(write.id);
            if (write.kind === "set")
                batch.set(ref, write.game, { merge: true });
            else
                batch.delete(ref);
        }
        await batch.commit();
    }
}
/** Centralized provider fetch, normalization, deterministic de-duplication and reconciliation. */
async function syncGoalV1Fixtures(apiKey, options = {}) {
    const source = options.source ?? new goalApiClient_1.GoalApiClient(apiKey);
    const persistence = options.persistence ?? firestorePersistence(admin.firestore());
    const names = options.names ?? { nameJa: teamIdentity_1.v1TeamNameJa };
    const targets = options.targets ?? exports.V1_GOAL_TARGETS;
    const games = new Map();
    const unsupported = new Set();
    const skipCounts = {};
    let fetched = 0;
    let duplicates = 0;
    for (const target of targets) {
        const countingSource = { fixtures: async (teamId) => {
                const fixtures = await source.fixtures(teamId);
                fetched += fixtures.length;
                return fixtures;
            } };
        const result = await (0, syncOrchestrator_1.orchestrateGoalTeamFixtures)(countingSource, target, v1CompetitionBindings_1.V1_GOAL_MEMBERSHIP_BINDINGS, names, options.now);
        for (const skipped of result.skipped) {
            skipCounts[skipped.reason] = (skipCounts[skipped.reason] ?? 0) + 1;
            // Unsupported active-binding state retracts a formerly published event. Anomalies preserve it.
            if (skipped.reason === "unsupported_status") {
                const id = stableGoalGameId(skipped.fixtureId);
                if (games.has(id))
                    throw new Error(`Conflicting supported/unsupported GOAL fixture: ${skipped.fixtureId}`);
                unsupported.add(id);
            }
        }
        for (const game of result.games) {
            const id = stableGoalGameId(game.sourceFixtureId);
            const previous = games.get(id);
            if (unsupported.has(id))
                throw new Error(`Conflicting supported/unsupported GOAL fixture: ${game.sourceFixtureId}`);
            if (previous) {
                duplicates += 1;
                if (gameSignature(previous) !== gameSignature(game)) {
                    throw new Error(`Conflicting GOAL fixture returned by target feeds: ${game.sourceFixtureId}`);
                }
            }
            else
                games.set(id, game);
        }
    }
    const writes = [
        ...[...games].sort(([a], [b]) => a.localeCompare(b)).map(([id, game]) => ({ kind: "set", id, game })),
        ...[...unsupported].sort().map(id => ({ kind: "delete", id })),
    ];
    await persistGoalWrites(persistence, writes);
    const summary = { targets: targets.length, providerFixturesFetched: fetched,
        gamesUpserted: games.size, gamesDeleted: unsupported.size, duplicates, skipCounts,
        providerAnomalies: skipCounts.provider_data_anomaly ?? 0 };
    console.info("GOAL V1 sync complete", summary);
    return summary;
}
function gameSignature(game) {
    return JSON.stringify({ ...game, startTimeUTC: game.startTimeUTC.toMillis() });
}
//# sourceMappingURL=syncGoalV1.js.map