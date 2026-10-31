"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultDisplayLanguage = defaultDisplayLanguage;
exports.confirmedJapaneseName = confirmedJapaneseName;
exports.displayTeamName = displayTeamName;
exports.isJapaneseCountry = isJapaneseCountry;
const clubPresentation_1 = require("./clubPresentation");
const japaneseDomesticFootball_1 = require("./japaneseDomesticFootball");
function defaultDisplayLanguage(competitionKey) {
    return (0, japaneseDomesticFootball_1.isJapaneseDomesticCompetition)(competitionKey) ? "ja" : "en";
}
function confirmedJapaneseName(providerName) {
    return (0, clubPresentation_1.clubPresentation)([providerName])?.nameJa || undefined;
}
const CANONICAL_NAMES = Object.freeze({
    kawasaki_frontale: { ja: "川崎フロンターレ", en: "Kawasaki Frontale" },
    arsenal: { ja: "アーセナル", en: "Arsenal" },
});
/** A language override and canonical team id are optional presentation inputs. */
function displayTeamName(competitionKey, names, languageOverride, teamId, country) {
    const value = (candidate) => typeof candidate === "string" ? candidate.trim() : "";
    const ja = value(names.japanese);
    const en = value(names.english);
    const provider = value(names.provider);
    // A Japanese team or person (provider country) keeps Japanese outside
    // Japanese competitions. No hand-kept id list: rosters change too often.
    const language = languageOverride ??
        (isJapaneseCountry(country) ? "ja" : defaultDisplayLanguage(competitionKey));
    const canonical = teamId === undefined ? undefined : CANONICAL_NAMES[teamId];
    if (canonical)
        return canonical[language];
    const isFootball = competitionKey?.startsWith("football_") ?? false;
    const evidence = isFootball ? (0, clubPresentation_1.clubPresentation)([en, provider, ja], competitionKey) : undefined;
    const confirmed = language === "en" ? evidence?.nameEn : evidence?.nameJa;
    if (confirmed)
        return confirmed;
    // Outside football, nameJa / nameEn come from our own master data, so the
    // requested language field is used directly (mirrors the app policy).
    if (!isFootball) {
        const requested = language === "ja" ? ja : en;
        if (requested)
            return requested;
    }
    // A catalog miss/conflict is final. Never retry fields independently with a
    // lossy normalizer: qualifiers and conflicting evidence must remain intact.
    // GOAL stores the original participant in provider; En is the legacy copy.
    // Field precedence is provenance, not a choice between catalog candidates.
    return provider || en || ja;
}
function isJapaneseCountry(country) {
    if (typeof country !== "string")
        return false;
    const value = country.trim().toLowerCase();
    return value === "japan" || value === "jp" || value === "jpn" || value === "日本";
}
//# sourceMappingURL=teamDisplayNamePolicy.js.map