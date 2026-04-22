import { getFirestore } from "firebase-admin/firestore";
import { TranslationMapDoc } from "../types";

const COLLECTION = "translationMaps";

// In-memory cache to avoid repeated Firestore reads within a function invocation
const cache: Record<string, TranslationMapDoc> = {};

/**
 * Load the translation map for a given sport type from Firestore.
 * Falls back to the English name if no mapping is found.
 */
export async function getTranslationMap(
  sportType: string
): Promise<TranslationMapDoc> {
  if (cache[sportType]) return cache[sportType];

  const db = getFirestore();
  const doc = await db.collection(COLLECTION).doc(sportType).get();

  if (!doc.exists) {
    const empty: TranslationMapDoc = { teams: {}, leagues: {} };
    cache[sportType] = empty;
    return empty;
  }

  const data = doc.data() as TranslationMapDoc;
  cache[sportType] = data;
  return data;
}

/**
 * Translate an English team name to Japanese.
 * Returns the English name unchanged if no mapping exists.
 */
export function translateTeamName(
  map: TranslationMapDoc,
  nameEn: string
): string {
  return map.teams[nameEn] ?? nameEn;
}

/**
 * Translate an English league name to Japanese.
 */
export function translateLeagueName(
  map: TranslationMapDoc,
  nameEn: string
): string {
  return map.leagues[nameEn] ?? nameEn;
}
