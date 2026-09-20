export type DisplayLanguage = "ja" | "en";

const JAPANESE_COMPETITIONS = new Set([
  "football_j1", "football_j_league_cup", "football_emperor_cup",
]);

export function defaultDisplayLanguage(competitionKey: string | undefined): DisplayLanguage {
  return JAPANESE_COMPETITIONS.has(competitionKey ?? "") ? "ja" : "en";
}

export function confirmedJapaneseName(providerName: string): string | undefined {
  return japaneseClubDisplayName(providerName);
}

export interface TeamDisplayNames {
  japanese?: unknown;
  english?: unknown;
  provider?: unknown;
}

const CANONICAL_NAMES: Readonly<Record<string, { ja: string; en: string }>> = Object.freeze({
  kawasaki_frontale: { ja: "川崎フロンターレ", en: "Kawasaki Frontale" },
  arsenal: { ja: "アーセナル", en: "Arsenal" },
});

/** A language override and canonical team id are optional presentation inputs. */
export function displayTeamName(
  competitionKey: string | undefined,
  names: TeamDisplayNames,
  languageOverride?: DisplayLanguage,
  teamId?: string
): string {
  const value = (candidate: unknown) => typeof candidate === "string" ? candidate.trim() : "";
  const ja = value(names.japanese);
  const en = value(names.english);
  const provider = value(names.provider);
  const language = languageOverride ?? defaultDisplayLanguage(competitionKey);
  const canonical = teamId === undefined ? undefined : CANONICAL_NAMES[teamId];
  if (canonical) return canonical[language];
  if (language === "en") return en || provider || ja;
  const confirmed = confirmedJapaneseName(en) ?? confirmedJapaneseName(provider) ?? confirmedJapaneseName(ja);
  if (confirmed) return confirmed;
  if (/[\u3040-\u30ff\u3400-\u9fff]/u.test(ja)) return ja;
  return provider || en || ja;
}
import { japaneseClubDisplayName } from "./japaneseClubDisplayEvidence";
