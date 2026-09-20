import { japaneseClubDisplayName } from "./japaneseClubDisplayEvidence";

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
  canonicalTeamId?: unknown;
}

const CANONICAL_NAMES: Readonly<Record<string, { ja: string; en: string }>> = Object.freeze({
  kawasaki_frontale: { ja: "川崎フロンターレ", en: "Kawasaki Frontale" },
  arsenal: { ja: "アーセナル", en: "Arsenal" },
});

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
  const canonicalTeamId = value(names.canonicalTeamId);
  const canonical = CANONICAL_NAMES[canonicalTeamId];
  if (canonical) return language === "ja" ? canonical.ja : canonical.en;
  if (language === "en") return en || provider || ja;
  const confirmed = confirmedJapaneseName(en) ?? confirmedJapaneseName(provider) ?? confirmedJapaneseName(ja);
  if (confirmed) return confirmed;
  if (/[\u3040-\u30ff\u3400-\u9fff]/u.test(ja)) return ja;
  return provider || en || ja;
}
