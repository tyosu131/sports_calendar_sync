import entries from './teamPresentationCatalog.json';

export function presentationNameKey(value: string): string {
  return value.replace(/[！-～]/g, c => String.fromCharCode(c.charCodeAt(0) - 0xfee0))
    .toLowerCase().replace(/[\s.\-・&]/g, '');
}

/** Exact unique display evidence only; never assigns a canonical/provider ID. */
export function clubPresentation(names: readonly string[], competitionKey?: string) {
  const keys = new Set(names.map(presentationNameKey).filter(Boolean));
  const matches = entries.filter(entry =>
    entry.aliases.some(alias => keys.has(presentationNameKey(alias))) ||
    (entry.competitionKeys.includes(competitionKey ?? '') &&
      entry.scopedAliases.some(alias => keys.has(presentationNameKey(alias)))));
  return matches.length === 1 ? matches[0] : undefined;
}
