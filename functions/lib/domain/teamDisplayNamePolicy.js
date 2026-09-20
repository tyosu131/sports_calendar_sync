"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultDisplayLanguage = defaultDisplayLanguage;
exports.confirmedJapaneseName = confirmedJapaneseName;
exports.displayTeamName = displayTeamName;
const JAPANESE_COMPETITIONS = new Set([
    "football_j1", "football_j_league_cup", "football_emperor_cup",
]);
function defaultDisplayLanguage(competitionKey) {
    return JAPANESE_COMPETITIONS.has(competitionKey ?? "") ? "ja" : "en";
}
function confirmedJapaneseName(providerName) {
    return (0, japaneseClubDisplayEvidence_1.japaneseClubDisplayName)(providerName);
}
const CANONICAL_NAMES = Object.freeze({
    kawasaki_frontale: { ja: "川崎フロンターレ", en: "Kawasaki Frontale" },
    arsenal: { ja: "アーセナル", en: "Arsenal" },
});
/** A language override and canonical team id are optional presentation inputs. */
function displayTeamName(competitionKey, names, languageOverride, teamId) {
    const value = (candidate) => typeof candidate === "string" ? candidate.trim() : "";
    const ja = value(names.japanese);
    const en = value(names.english);
    const provider = value(names.provider);
    const language = languageOverride ?? defaultDisplayLanguage(competitionKey);
    const canonical = teamId === undefined ? undefined : CANONICAL_NAMES[teamId];
    if (canonical)
        return canonical[language];
    if (language === "en")
        return en || provider || ja;
    const confirmed = confirmedJapaneseName(en) ?? confirmedJapaneseName(provider) ?? confirmedJapaneseName(ja);
    if (confirmed)
        return confirmed;
    if (/[\u3040-\u30ff\u3400-\u9fff]/u.test(ja))
        return ja;
    return provider || en || ja;
}
const japaneseClubDisplayEvidence_1 = require("./japaneseClubDisplayEvidence");
//# sourceMappingURL=teamDisplayNamePolicy.js.map