"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getTranslationMap = getTranslationMap;
exports.translateTeamName = translateTeamName;
exports.translateLeagueName = translateLeagueName;
const firestore_1 = require("firebase-admin/firestore");
const COLLECTION = "translationMaps";
// In-memory cache to avoid repeated Firestore reads within a function invocation
const cache = {};
/**
 * Load the translation map for a given sport type from Firestore.
 * Falls back to the English name if no mapping is found.
 */
async function getTranslationMap(sportType) {
    if (cache[sportType])
        return cache[sportType];
    const db = (0, firestore_1.getFirestore)();
    const doc = await db.collection(COLLECTION).doc(sportType).get();
    if (!doc.exists) {
        const empty = { teams: {}, leagues: {} };
        cache[sportType] = empty;
        return empty;
    }
    const data = doc.data();
    cache[sportType] = data;
    return data;
}
/**
 * Translate an English team name to Japanese.
 * Returns the English name unchanged if no mapping exists.
 */
function translateTeamName(map, nameEn) {
    return map.teams[nameEn] ?? nameEn;
}
/**
 * Translate an English league name to Japanese.
 */
function translateLeagueName(map, nameEn) {
    return map.leagues[nameEn] ?? nameEn;
}
//# sourceMappingURL=translation.js.map