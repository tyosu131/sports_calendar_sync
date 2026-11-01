import * as admin from "firebase-admin";
import { TheSportsDbClient, TsdbEventSource, TsdbTeamInfo } from "../providers/thesportsdb/client";
import { clubPresentation } from "../domain/clubPresentation";

/** Team color lookups per run. One burst stays under the provider's rate limit. */
export const TEAM_COLOR_LOOKUPS_PER_RUN = 10;
/** A team the provider had no color for is asked again after this many days. */
export const TEAM_COLOR_RECHECK_DAYS = 30;
export const TEAM_COLOR_RUN_BUDGET_MS = 240_000;
/** Bump when matching rules change, so teams checked under older rules are looked at again. */
export const TEAM_COLOR_CHECK_VERSION = "2";

/**
 * Competitions whose team colors are read, and what the provider must say
 * about a matching team. A name alone is never trusted: sport and country
 * must agree, so "Tokyo" or "Japan" cannot pick up another sport's team.
 */
export const TEAM_COLOR_SCOPES: Readonly<Record<string, { sport: string; country: string } | "tsdb-id">> = Object.freeze({
  americanfootball_nfl: "tsdb-id",
  football_j1: { sport: "Soccer", country: "Japan" },
  football_j2: { sport: "Soccer", country: "Japan" },
  football_j3: { sport: "Soccer", country: "Japan" },
  football_premier: { sport: "Soccer", country: "England" },
});

export interface TeamColorTarget {
  id: string;
  nameEn: string;
  competitionKey: string;
  /** Provider team id, set for teams that were created from provider data. */
  sourceTeamId?: string;
}

export interface TeamColorPersistence {
  /** Teams in scope with no color and no recent check, provider-id teams first. */
  targets(now: Date): Promise<TeamColorTarget[]>;
  /** Merge fields into teams/{id}. */
  update(teamId: string, fields: Record<string, string>): Promise<void>;
}

export function firestoreTeamColorPersistence(db: admin.firestore.Firestore): TeamColorPersistence {
  return {
    targets: async (now) => {
      const keys = Object.keys(TEAM_COLOR_SCOPES);
      const snapshot = await db.collection("teams").where("competitionKey", "in", keys).get();
      const cutoff = now.getTime() - TEAM_COLOR_RECHECK_DAYS * 24 * 60 * 60 * 1000;
      const result: TeamColorTarget[] = [];
      for (const doc of snapshot.docs) {
        if (doc.get("presentationColor")) continue;
        const checked = Date.parse(String(doc.get("presentationColorCheckedAt") ?? ""));
        if (Number.isFinite(checked) && checked > cutoff &&
            doc.get("presentationColorCheckVersion") === TEAM_COLOR_CHECK_VERSION) continue;
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

function nameKey(value: string): string {
  return value.normalize("NFKC").toLowerCase().replace(/[^\p{L}\p{N}]/gu, "");
}

/**
 * English names that identify a club: its own name plus the English aliases in
 * the reviewed presentation catalog (e.g. "Kashima" and "Kashima Antlers").
 */
export function clubNames(nameEn: string): string[] {
  const entry = clubPresentation([nameEn]);
  const aliases = (entry?.aliases ?? []).filter((alias) => /^[\x20-\x7e]+$/.test(alias));
  return [...new Set([nameEn, ...aliases])];
}

/**
 * The one provider team that is the same club, or undefined. Sport and country
 * must agree and the provider name must equal one of [names] exactly.
 */
export function matchingTeam(
  candidates: readonly TsdbTeamInfo[],
  names: string | readonly string[],
  scope: { sport: string; country: string }
): TsdbTeamInfo | undefined {
  const keys = new Set((typeof names === "string" ? [names] : names).map(nameKey).filter(Boolean));
  if (keys.size === 0) return undefined;
  const matches = candidates.filter((team) =>
    team.strSport === scope.sport && team.strCountry === scope.country && keys.has(nameKey(team.strTeam)));
  return matches.length === 1 ? matches[0] : undefined;
}

export interface TeamColorSummary {
  looked: number;
  colorsSaved: number;
  noColor: number;
  /** Teams found at the provider with no color, as `id (name)`, to fill in by hand. */
  noColorTeams: string[];
  /** Teams the search could not match to one provider team (name or country differs). */
  noMatchTeams: string[];
  failed: string[];
}

export interface SyncTeamColorsOptions {
  source?: TsdbEventSource;
  persistence?: TeamColorPersistence;
  now?: () => Date;
  limit?: number;
  budgetMs?: number;
}

/**
 * Reads real team colors from the provider, a few teams per run, and saves
 * `presentationColor` (`#RRGGBB`) on the team. A club the provider has no
 * color for is marked as checked and asked again later. Nothing is invented.
 */
export async function syncTeamColors(apiKey: string, options: SyncTeamColorsOptions = {}): Promise<TeamColorSummary> {
  const startedAt = Date.now();
  let source = options.source;
  if (!source) {
    const client = new TheSportsDbClient(apiKey);
    client.setDeadline(startedAt + (options.budgetMs ?? TEAM_COLOR_RUN_BUDGET_MS));
    source = client;
  }
  const persistence = options.persistence ?? firestoreTeamColorPersistence(admin.firestore());
  const now = (options.now ?? (() => new Date()))();
  const summary: TeamColorSummary = { looked: 0, colorsSaved: 0, noColor: 0, noColorTeams: [], noMatchTeams: [], failed: [] };

  const targets = (await persistence.targets(now)).slice(0, options.limit ?? TEAM_COLOR_LOOKUPS_PER_RUN);
  for (const target of targets) {
    const scope = TEAM_COLOR_SCOPES[target.competitionKey];
    if (!scope) continue;
    try {
      let color: string | undefined;
      let providerTeamId: string | undefined;
      if (scope === "tsdb-id") {
        if (!target.sourceTeamId || !source.lookupTeamColor) continue;
        const found = await source.lookupTeamColor(target.sourceTeamId);
        color = found?.primaryColor;
        providerTeamId = found ? target.sourceTeamId : undefined;
      } else {
        if (!source.searchTeams) continue;
        const found = matchingTeam(await source.searchTeams(target.nameEn), clubNames(target.nameEn), scope);
        color = found?.primaryColor;
        providerTeamId = found?.idTeam;
      }
      summary.looked += 1;
      if (color) {
        await persistence.update(target.id, {
          presentationColor: color,
          presentationColorSource: `thesportsdb:${providerTeamId}`,
          presentationColorCheckedAt: now.toISOString(),
          presentationColorCheckVersion: TEAM_COLOR_CHECK_VERSION,
        });
        summary.colorsSaved += 1;
      } else {
        await persistence.update(target.id, {
          presentationColorCheckedAt: now.toISOString(),
          presentationColorCheckVersion: TEAM_COLOR_CHECK_VERSION,
        });
        summary.noColor += 1;
        // Found at the provider without a color, or not found at all?
        (providerTeamId ? summary.noColorTeams : summary.noMatchTeams).push(`${target.id} (${target.nameEn})`);
      }
    } catch (error) {
      summary.failed.push(target.id);
      console.error("Team color lookup failed", { teamId: target.id, error: error instanceof Error ? error.message : String(error) });
      break; // Throttled or down: keep what was saved and stop this run.
    }
  }
  console.info("Team color sync complete", summary);
  return summary;
}
