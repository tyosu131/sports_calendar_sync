"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultDisplayLanguage = defaultDisplayLanguage;
exports.confirmedJapaneseName = confirmedJapaneseName;
exports.displayTeamName = displayTeamName;
const clubPresentation_1 = require("./clubPresentation");
const JAPANESE_COMPETITIONS = new Set([
    "football_j1", "football_j2", "football_j3", "football_j_league_cup", "football_emperor_cup",
]);
function defaultDisplayLanguage(competitionKey) {
    return JAPANESE_COMPETITIONS.has(competitionKey ?? "") ? "ja" : "en";
}
function confirmedJapaneseName(providerName) {
    return (0, clubPresentation_1.clubPresentation)([providerName])?.nameJa || undefined;
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
    const evidence = competitionKey?.startsWith("football_") ? (0, clubPresentation_1.clubPresentation)([en, provider, ja], competitionKey) : undefined;
    const confirmed = language === "en" ? evidence?.nameEn : evidence?.nameJa;
    if (confirmed)
        return confirmed;
    // A catalog miss/conflict is final. Never retry fields independently with a
    // lossy normalizer: qualifiers and conflicting evidence must remain intact.
    // GOAL stores the original participant in provider; En is the legacy copy.
    // Field precedence is provenance, not a choice between catalog candidates.
    return provider || en || ja;
}
//# sourceMappingURL=teamDisplayNamePolicy.js.map