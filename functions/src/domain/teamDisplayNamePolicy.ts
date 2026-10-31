export type DisplayLanguage = "ja" | "en";
import { clubPresentation } from "./clubPresentation";
import { isJapaneseDomesticCompetition } from "./japaneseDomesticFootball";

export function defaultDisplayLanguage(competitionKey: string | undefined): DisplayLanguage {
  return isJapaneseDomesticCompetition(competitionKey) ? "ja" : "en";
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
  teamId?: string,
  country?: unknown
): string {
  const value = (candidate: unknown) => typeof candidate === "string" ? candidate.trim() : "";
  const ja = value(names.japanese);
  const en = value(names.english);
  const provider = value(names.provider);
  // A Japanese team or person (provider country) keeps Japanese outside
  // Japanese competitions. No hand-kept id list: rosters change too often.
  const language = languageOverride ??
    (isJapaneseCountry(country) ? "ja" : defaultDisplayLanguage(competitionKey));
  const canonical = teamId === undefined ? undefined : CANONICAL_NAMES[teamId];
  if (canonical) return canonical[language];
  const isFootball = competitionKey?.startsWith("football_") ?? false;
  const evidence = isFootball ? clubPresentation([en, provider, ja], competitionKey) : undefined;
  const confirmed = language === "en" ? evidence?.nameEn : evidence?.nameJa;
  if (confirmed) return confirmed;
  // Outside football, nameJa / nameEn come from our own master data, so the
  // requested language field is used directly (mirrors the app policy).
  if (!isFootball) {
    const requested = language === "ja" ? ja : en;
    if (requested) return requested;
  }
  // A catalog miss/conflict is final. Never retry fields independently with a
  // lossy normalizer: qualifiers and conflicting evidence must remain intact.
  // GOAL stores the original participant in provider; En is the legacy copy.
  // Field precedence is provenance, not a choice between catalog candidates.
  return provider || en || ja;
}

export function isJapaneseCountry(country: unknown): boolean {
  if (typeof country !== "string") return false;
  const value = country.trim().toLowerCase();
  return value === "japan" || value === "jp" || value === "jpn" || value === "日本";
}
