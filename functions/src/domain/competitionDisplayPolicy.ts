export interface CompetitionDisplayMetadata {
  nameJa: string;
  nameEn: string;
  compact: string;
  defaultLanguage: "ja" | "en";
}

const COMPETITIONS: Readonly<Record<string, CompetitionDisplayMetadata>> = Object.freeze({
  football_j1: { nameJa: "J1リーグ", nameEn: "J1 League", compact: "J1", defaultLanguage: "ja" },
  football_j_league_cup: {
    nameJa: "ルヴァンカップ", nameEn: "J.League Cup", compact: "ルヴァン", defaultLanguage: "ja",
  },
  football_emperor_cup: {
    nameJa: "天皇杯", nameEn: "Emperor's Cup", compact: "天皇杯", defaultLanguage: "ja",
  },
  football_premier: {
    nameJa: "プレミアリーグ", nameEn: "Premier League", compact: "PL", defaultLanguage: "en",
  },
  football_champions_league: {
    nameJa: "UEFAチャンピオンズリーグ", nameEn: "Champions League", compact: "UCL", defaultLanguage: "en",
  },
  football_league_cup: {
    nameJa: "リーグカップ", nameEn: "League Cup", compact: "EFL Cup", defaultLanguage: "en",
  },
});

export function competitionDisplayMetadata(
  competitionKey: string | undefined
): CompetitionDisplayMetadata | undefined {
  return competitionKey === undefined ? undefined : COMPETITIONS[competitionKey];
}

export function defaultCompetitionDisplayName(competitionKey: string | undefined): string | undefined {
  const metadata = competitionDisplayMetadata(competitionKey);
  if (!metadata) return undefined;
  return metadata.defaultLanguage === "ja" ? metadata.nameJa : metadata.nameEn;
}
