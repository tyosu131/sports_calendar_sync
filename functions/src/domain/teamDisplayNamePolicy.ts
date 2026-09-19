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

/** Future explicit preference is the final optional argument. */
export function displayTeamName(
  competitionKey: string | undefined,
  names: TeamDisplayNames,
  languageOverride?: DisplayLanguage
): string {
  const value = (candidate: unknown) => typeof candidate === "string" ? candidate.trim() : "";
  const ja = value(names.japanese);
  const en = value(names.english);
  const provider = value(names.provider);
  const language = languageOverride ?? defaultDisplayLanguage(competitionKey);
  if (language === "en") return en || provider || ja;
  const confirmed = confirmedJapaneseName(en) ?? confirmedJapaneseName(provider) ?? confirmedJapaneseName(ja);
  if (confirmed) return confirmed;
  if (/[\u3040-\u30ff\u3400-\u9fff]/u.test(ja)) return ja;
  return provider || en || ja;
}
import { japaneseClubDisplayName } from "./japaneseClubDisplayEvidence";
