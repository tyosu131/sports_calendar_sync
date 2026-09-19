"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultDisplayLanguage = defaultDisplayLanguage;
exports.confirmedJapaneseName = confirmedJapaneseName;
exports.displayTeamName = displayTeamName;
const JAPANESE_COMPETITIONS = new Set([
    "football_j1", "football_j_league_cup", "football_emperor_cup",
]);
// Confirmed repository team-master evidence. Aliases are presentation-only and
// must never be used to infer a canonical Team identity.
const JAPANESE_BY_ENGLISH = Object.freeze({
    "Kashima": "鹿島アントラーズ", "Kashima Antlers": "鹿島アントラーズ",
    "Mito Hollyhock": "水戸ホーリーホック", "Urawa Reds": "浦和レッズ",
    "JEF United Chiba": "ジェフユナイテッド千葉", "JEF Chiba": "ジェフユナイテッド千葉",
    "Kashiwa Reysol": "柏レイソル", "FC Tokyo": "ＦＣ東京", "Tokyo Verdy": "東京ヴェルディ",
    "FC Machida Zelvia": "ＦＣ町田ゼルビア", "Machida Zelvia": "ＦＣ町田ゼルビア",
    "Kawasaki Frontale": "川崎フロンターレ", "Yokohama F・Marinos": "横浜Ｆ・マリノス",
    "Yokohama F. Marinos": "横浜Ｆ・マリノス", "Shimizu S-Pulse": "清水エスパルス",
    "Nagoya Grampus": "名古屋グランパス", "Kyoto Sanga F.C.": "京都サンガF.C.",
    "Kyoto Sanga": "京都サンガF.C.", "Gamba Osaka": "ガンバ大阪", "Cerezo Osaka": "セレッソ大阪",
    "Vissel Kobe": "ヴィッセル神戸", "Fagiano Okayama": "ファジアーノ岡山",
    "Sanfrecce Hiroshima": "サンフレッチェ広島", "Avispa Fukuoka": "アビスパ福岡",
    "V-Varen Nagasaki": "Ｖ・ファーレン長崎", "V. Varen Nagasaki": "Ｖ・ファーレン長崎",
});
function defaultDisplayLanguage(competitionKey) {
    return JAPANESE_COMPETITIONS.has(competitionKey ?? "") ? "ja" : "en";
}
function confirmedJapaneseName(providerName) {
    return JAPANESE_BY_ENGLISH[providerName.trim()];
}
/** Future explicit preference is the final optional argument. */
function displayTeamName(competitionKey, names, languageOverride) {
    const value = (candidate) => typeof candidate === "string" ? candidate.trim() : "";
    const ja = value(names.japanese);
    const en = value(names.english);
    const provider = value(names.provider);
    const language = languageOverride ?? defaultDisplayLanguage(competitionKey);
    if (language === "en")
        return en || provider || ja;
    const confirmed = confirmedJapaneseName(en) ?? confirmedJapaneseName(provider) ?? confirmedJapaneseName(ja);
    if (confirmed)
        return confirmed;
    if (/[\u3040-\u30ff\u3400-\u9fff]/u.test(ja))
        return ja;
    return provider || en || ja;
}
//# sourceMappingURL=teamDisplayNamePolicy.js.map