"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.competitionDisplayMetadata = competitionDisplayMetadata;
exports.defaultCompetitionDisplayName = defaultCompetitionDisplayName;
const COMPETITIONS = Object.freeze({
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
function competitionDisplayMetadata(competitionKey) {
    return competitionKey === undefined ? undefined : COMPETITIONS[competitionKey];
}
function defaultCompetitionDisplayName(competitionKey) {
    const metadata = competitionDisplayMetadata(competitionKey);
    if (!metadata)
        return undefined;
    return metadata.defaultLanguage === "ja" ? metadata.nameJa : metadata.nameEn;
}
//# sourceMappingURL=competitionDisplayPolicy.js.map