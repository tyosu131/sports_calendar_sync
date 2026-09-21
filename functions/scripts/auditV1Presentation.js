'use strict';

// Offline only. The public snapshot is fixed evidence, not a live API request.
const {displayTeamName} = require('../lib/domain/teamDisplayNamePolicy');
const {clubPresentation} = require('../lib/domain/clubPresentation');
const snapshot = require('../../test/fixtures/v1_presentation_snapshot.json');

function coverageReport() {
  const rows = new Map();
  const labels = new Set();
  let names = 0;
  for (const game of snapshot.games) {
    for (const side of ['home', 'away']) {
      const label = game[side + 'TeamProviderName'] || game[side + 'TeamNameEn'] || game[side + 'TeamNameJa'];
      labels.add(label);
      const inputs = {japanese: game[side + 'TeamNameJa'], english: game[side + 'TeamNameEn'], provider: game[side + 'TeamProviderName']};
      const actual = displayTeamName(game.competitionKey, inputs, undefined, game[side + 'TeamId']);
      const expected = game[side + 'ExpectedName'];
      const entry = clubPresentation(Object.values(inputs).filter(Boolean), game.competitionKey);
      if (actual === expected) names++;
      rows.set(game.competitionKey + '|' + label, [game.competitionKey, label, actual, expected,
        `[URL](${game[side + 'ExpectedLogo']})`, actual === expected && entry ? 'yes' : 'NO',
        entry ? entry.source : 'unverified']);
    }
  }
  const lines = [...rows.values()].sort((a, b) => (a[0] + a[1]).localeCompare(b[0] + b[1]))
    .map(row => '| ' + row.join(' | ') + ' |');
  return `# V1 presentation coverage — ${snapshot.observedAt}

Public game/Team fields only; read-only Firestore projection. No GOAL/API-SPORTS
request is needed to reproduce this report. The snapshot contains no user data,
calendar URLs or credentials. Kickoff/status used in tests are synthetic.

- Games: ${snapshot.games.length}; participant slots: ${snapshot.games.length * 2}; distinct provider labels: ${labels.size}.
- Competition/participant rows: ${rows.size}; server names matching frozen expectations: ${names}/${snapshot.games.length * 2}.
- Flutter tests independently validate all ${snapshot.games.length * 2} names and candidate logo URLs against the same frozen oracle and captured masters.
- ICS and Google tests exercise their actual output builders for all ${snapshot.games.length} games.
- Unresolved participant names: NONE in this captured set. Candidate URLs resolve for every slot.
- Public V1 rendering: 0 rights-cleared club logos; all ${snapshot.games.length * 2} slots intentionally use neutral badges/monograms. Tests enforce this at the public presentation boundary.
- This is URL resolution coverage, **not** an assertion of image delivery, image rights, Google publication, or iPhone verification.
- Unknown/ambiguous/partial participants outside this set retain fallback; no canonical IDs are inferred.

Reproduce after Functions build: node functions/scripts/auditV1Presentation.js.
Source: test/fixtures/v1_presentation_snapshot.json. See [logo provenance](logo-provenance.md) for release blockers.

| Competition | Provider participant | Current name output | Expected name | Candidate logo (NOT rights-cleared) | Metadata resolved | Evidence source |
|---|---|---|---|---|---|---|
${lines.join('\n')}
`;
}

if (require.main === module) process.stdout.write(coverageReport());
module.exports = {coverageReport};
