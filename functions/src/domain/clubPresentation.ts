import entries from './teamPresentationCatalog.json';
import { isJapaneseDomesticFootballCompetition } from './japaneseDomesticFootball';

export function presentationNameKey(value: string): string {
  return value.replace(/[！-～]/g, c => String.fromCharCode(c.charCodeAt(0) - 0xfee0))
    .toLowerCase().replace(/[\s.\-・&]/g, '');
}

/** Exact unique display evidence only; never assigns a canonical/provider ID. */
export function clubPresentation(names: readonly string[], competitionKey?: string) {
  const keys = new Set(names.map(presentationNameKey).filter(Boolean));
  const matches = entries.filter(entry =>
    entry.aliases.some(alias => keys.has(presentationNameKey(alias))) ||
    (acceptsScopedAlias(entry.competitionKeys, competitionKey) &&
      entry.scopedAliases.some(alias => keys.has(presentationNameKey(alias)))));
  return matches.length === 1 ? matches[0] : undefined;
}

/** Japanese-scoped aliases follow every domestic football competition key. */
function acceptsScopedAlias(entryKeys: readonly string[], competitionKey?: string): boolean {
  if (!competitionKey) return false;
  if (entryKeys.includes(competitionKey)) return true;
  if (!isJapaneseDomesticFootballCompetition(competitionKey)) return false;
  return entryKeys.length > 0 && entryKeys.every(isJapaneseDomesticFootballCompetition);
}
