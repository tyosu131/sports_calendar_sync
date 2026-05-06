/**
 * searchKeywords.js
 *
 * Shared utility for generating Firestore `searchKeywords` arrays.
 *
 * Design principles:
 *   - All teams share the same generation logic (no team-specific code).
 *   - Mid-string matches are handled by passing explicit aliases, not by
 *     mechanically generating all substrings (which would bloat the array
 *     and reduce search precision as the team count grows).
 *   - English strings are lowercased; Japanese strings are kept as-is.
 *   - Duplicates are removed via a Set before returning.
 *
 * Usage:
 *   const { generateSearchKeywords } = require('./searchKeywords');
 *
 *   generateSearchKeywords({
 *     nameJa: '鹿島アントラーズ',
 *     nameEn: 'Kashima',
 *     aliases: ['鹿島', 'アントラーズ', 'Kashima Antlers', 'Antlers'],
 *   });
 *   // → ['鹿', '鹿島', '鹿島ア', ..., 'ア', 'アン', ..., 'k', 'ka', ..., 'kashima antlers', ...]
 */

'use strict';

/**
 * Generate all leading prefixes of a string (length 1 … str.length).
 * Returns an empty array for empty / whitespace-only input.
 *
 * @param {string} str
 * @returns {string[]}
 */
function prefixes(str) {
  const s = str.trim();
  if (!s) return [];
  const result = [];
  for (let i = 1; i <= s.length; i++) {
    result.push(s.slice(0, i));
  }
  return result;
}

/**
 * Generate search keywords from a team's name fields and optional aliases.
 *
 * Rules:
 *   - nameJa  : generate all leading prefixes (Japanese, kept as-is).
 *   - nameEn  : lowercase the whole phrase, generate all leading prefixes,
 *               then also split by spaces and generate prefixes per token.
 *   - aliases : each alias is processed the same way as nameJa (if it looks
 *               like Japanese) or nameEn (if it contains only ASCII).
 *               In practice, pass both Japanese and English aliases as needed.
 *
 * @param {{ nameJa?: string, nameEn?: string, aliases?: string[] }} opts
 * @returns {string[]}
 */
function generateSearchKeywords({ nameJa = '', nameEn = '', aliases = [] } = {}) {
  const set = new Set();

  // Helper: add all prefixes of a string to the set.
  function addPrefixes(str) {
    for (const p of prefixes(str)) {
      set.add(p);
    }
  }

  // Helper: process an English phrase — lowercase, add phrase prefixes,
  // then split into tokens and add each token's prefixes.
  function addEnglishPhrase(phrase) {
    const lower = phrase.trim().toLowerCase();
    if (!lower) return;
    // Prefixes of the full phrase (e.g. "kashima antlers" → "k", "ka", …)
    addPrefixes(lower);
    // Also add the full phrase itself (for exact-phrase search).
    set.add(lower);
    // Per-token prefixes (e.g. "antlers" → "a", "an", "ant", …)
    for (const token of lower.split(/\s+/)) {
      if (token) addPrefixes(token);
    }
  }

  // Determine whether a string is primarily ASCII (treat as English).
  function isAscii(str) {
    return /^[\x00-\x7F]*$/.test(str.trim());
  }

  // Process nameJa (Japanese).
  if (nameJa) addPrefixes(nameJa.trim());

  // Process nameEn (English).
  if (nameEn) addEnglishPhrase(nameEn);

  // Process aliases — route to Japanese or English handler based on content.
  for (const alias of aliases) {
    if (!alias || !alias.trim()) continue;
    if (isAscii(alias)) {
      addEnglishPhrase(alias);
    } else {
      addPrefixes(alias.trim());
    }
  }

  // Remove empty strings (defensive).
  set.delete('');

  return Array.from(set);
}

module.exports = { generateSearchKeywords };
