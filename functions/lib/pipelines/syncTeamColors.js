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
exports.TEAM_COLOR_SCOPES = exports.TEAM_COLOR_RUN_BUDGET_MS = exports.TEAM_COLOR_RECHECK_DAYS = exports.TEAM_COLOR_LOOKUPS_PER_RUN = void 0;
exports.firestoreTeamColorPersistence = firestoreTeamColorPersistence;
exports.matchingTeam = matchingTeam;
exports.syncTeamColors = syncTeamColors;
const admin = __importStar(require("firebase-admin"));
const client_1 = require("../providers/thesportsdb/client");
/** Team color lookups per run. One burst stays under the provider's rate limit. */
exports.TEAM_COLOR_LOOKUPS_PER_RUN = 10;
/** A team the provider had no color for is asked again after this many days. */
exports.TEAM_COLOR_RECHECK_DAYS = 30;
exports.TEAM_COLOR_RUN_BUDGET_MS = 240000;
/**
 * Competitions whose team colors are read, and what the provider must say
 * about a matching team. A name alone is never trusted: sport and country
 * must agree, so "Tokyo" or "Japan" cannot pick up another sport's team.
 */
exports.TEAM_COLOR_SCOPES = Object.freeze({
    americanfootball_nfl: "tsdb-id",
    football_j1: { sport: "Soccer", country: "Japan" },
    football_j2: { sport: "Soccer", country: "Japan" },
    football_j3: { sport: "Soccer", country: "Japan" },
    football_premier: { sport: "Soccer", country: "England" },
});
function firestoreTeamColorPersistence(db) {
    return {
        targets: async (now) => {
            const keys = Object.keys(exports.TEAM_COLOR_SCOPES);
            const snapshot = await db.collection("teams").where("competitionKey", "in", keys).get();
            const cutoff = now.getTime() - exports.TEAM_COLOR_RECHECK_DAYS * 24 * 60 * 60 * 1000;
            const result = [];
            for (const doc of snapshot.docs) {
                if (doc.get("presentationColor"))
                    continue;
                const checked = Date.parse(String(doc.get("presentationColorCheckedAt") ?? ""));
                if (Number.isFinite(checked) && checked > cutoff)
                    continue;
                const sourceTeamId = doc.get("sourceProvider") === "thesportsdb" ? doc.get("sourceTeamId") : undefined;
                result.push({
                    id: doc.id,
                    nameEn: String(doc.get("nameEn") ?? ""),
                    competitionKey: String(doc.get("competitionKey") ?? ""),
                    ...(typeof sourceTeamId === "string" ? { sourceTeamId } : {}),
                });
            }
            return result.sort((a, b) => Number(!!b.sourceTeamId) - Number(!!a.sourceTeamId) || a.id.localeCompare(b.id));
        },
        update: async (teamId, fields) => {
            await db.collection("teams").doc(teamId).set(fields, { merge: true });
        },
    };
}
function nameKey(value) {
    return value.normalize("NFKC").toLowerCase().replace(/[^\p{L}\p{N}]/gu, "");
}
/** The one provider team that is the same club, or undefined. Sport, country and exact name must agree. */
function matchingTeam(candidates, nameEn, scope) {
    const key = nameKey(nameEn);
    if (!key)
        return undefined;
    const matches = candidates.filter((team) => team.strSport === scope.sport && team.strCountry === scope.country && nameKey(team.strTeam) === key);
    return matches.length === 1 ? matches[0] : undefined;
}
/**
 * Reads real team colors from the provider, a few teams per run, and saves
 * `presentationColor` (`#RRGGBB`) on the team. A club the provider has no
 * color for is marked as checked and asked again later. Nothing is invented.
 */
async function syncTeamColors(apiKey, options = {}) {
    const startedAt = Date.now();
    let source = options.source;
    if (!source) {
        const client = new client_1.TheSportsDbClient(apiKey);
        client.setDeadline(startedAt + (options.budgetMs ?? exports.TEAM_COLOR_RUN_BUDGET_MS));
        source = client;
    }
    const persistence = options.persistence ?? firestoreTeamColorPersistence(admin.firestore());
    const now = (options.now ?? (() => new Date()))();
    const summary = { looked: 0, colorsSaved: 0, noColor: 0, noColorTeams: [], failed: [] };
    const targets = (await persistence.targets(now)).slice(0, options.limit ?? exports.TEAM_COLOR_LOOKUPS_PER_RUN);
    for (const target of targets) {
        const scope = exports.TEAM_COLOR_SCOPES[target.competitionKey];
        if (!scope)
            continue;
        try {
            let color;
            let providerTeamId;
            if (scope === "tsdb-id") {
                if (!target.sourceTeamId || !source.lookupTeamColor)
                    continue;
                const found = await source.lookupTeamColor(target.sourceTeamId);
                color = found?.primaryColor;
                providerTeamId = target.sourceTeamId;
            }
            else {
                if (!source.searchTeams)
                    continue;
                const found = matchingTeam(await source.searchTeams(target.nameEn), target.nameEn, scope);
                color = found?.primaryColor;
                providerTeamId = found?.idTeam;
            }
            summary.looked += 1;
            if (color) {
                await persistence.update(target.id, {
                    presentationColor: color,
                    presentationColorSource: `thesportsdb:${providerTeamId}`,
                    presentationColorCheckedAt: now.toISOString(),
                });
                summary.colorsSaved += 1;
            }
            else {
                await persistence.update(target.id, { presentationColorCheckedAt: now.toISOString() });
                summary.noColor += 1;
                summary.noColorTeams.push(`${target.id} (${target.nameEn})`);
            }
        }
        catch (error) {
            summary.failed.push(target.id);
            console.error("Team color lookup failed", { teamId: target.id, error: error instanceof Error ? error.message : String(error) });
            break; // Throttled or down: keep what was saved and stop this run.
        }
    }
    console.info("Team color sync complete", summary);
    return summary;
}
//# sourceMappingURL=syncTeamColors.js.map