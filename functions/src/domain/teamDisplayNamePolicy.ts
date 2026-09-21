export type DisplayLanguage = "ja" | "en";
import { clubPresentation } from "./clubPresentation";

const JAPANESE_COMPETITIONS = new Set([
  "football_j1", "football_j2", "football_j3", "football_j_league_cup", "football_emperor_cup",
]);

export function defaultDisplayLanguage(competitionKey: string | undefined): DisplayLanguage {
  return JAPANESE_COMPETITIONS.has(competitionKey ?? "") ? "ja" : "en";
}

export function confirmedJapaneseName(providerName: string): string | undefined {
  return clubPresentation([providerName])?.nameJa || undefined;
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
  const evidence = competitionKey?.startsWith("football_") ? clubPresentation([en, provider, ja], competitionKey) : undefined;
  const confirmed = language === "en" ? evidence?.nameEn : evidence?.nameJa;
  if (confirmed) return confirmed;
  // A catalog miss/conflict is final. Never retry fields independently with a
  // lossy normalizer: qualifiers and conflicting evidence must remain intact.
  // GOAL stores the original participant in provider; En is the legacy copy.
  // Field precedence is provenance, not a choice between catalog candidates.
  return provider || en || ja;
}
