"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isJapaneseDomesticFootballCompetition = isJapaneseDomesticFootballCompetition;
exports.isJapaneseDomesticCompetition = isJapaneseDomesticCompetition;
/**
 * Japanese domestic football competitions use Japanese canonical club names.
 *
 * J.League keys share the `football_j` prefix (J1, J2, J3, the J.League Cup,
 * and domestic specials such as `football_j2_j3_special`). A future J.League
 * key that keeps that prefix is domestic without another allowlist edit. The
 * Emperor's Cup does not use the prefix and is named explicitly. Premier
 * League, Champions League, and the English League Cup (`football_league_cup`)
 * stay outside. A missing key is not a domestic context. This does not
 * classify baseball, basketball, or other sports.
 */
function isJapaneseDomesticFootballCompetition(competitionKey) {
    const key = competitionKey?.trim() ?? "";
    if (!key)
        return false;
    return key.startsWith("football_j") || key === "football_emperor_cup";
}
const JAPANESE_DOMESTIC_NON_FOOTBALL_KEYS = ["baseball_npb", "basketball_b_league"];
/**
 * Japanese domestic competitions in any sport. Football uses
 * isJapaneseDomesticFootballCompetition; NPB and B.League keys (and keys that
 * extend them, e.g. `baseball_npb_farm`) are domestic. MLB, NBA, NFL, NHL and
 * UFC are not. Mirrors the app policy.
 */
function isJapaneseDomesticCompetition(competitionKey) {
    if (isJapaneseDomesticFootballCompetition(competitionKey))
        return true;
    const key = competitionKey?.trim() ?? "";
    if (!key)
        return false;
    return JAPANESE_DOMESTIC_NON_FOOTBALL_KEYS.some((prefix) => key === prefix || key.startsWith(`${prefix}_`));
}
//# sourceMappingURL=japaneseDomesticFootball.js.map