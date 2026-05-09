/**
 * verifyFootballStatusMapping.js
 *
 * Verifies API-SPORTS football fixture status short code mapping to the app
 * GameStatus values. This script is read-only: it does not initialize Firebase,
 * call API-SPORTS, read serviceAccountKey.json, or write Firestore.
 *
 * Usage:
 *   npm --prefix functions run build
 *   node functions/scripts/verifyFootballStatusMapping.js
 */

'use strict';

const { mapFootballStatus } = require('../lib/utils/timezone');

const EXPECTED_MAPPINGS = [
  // scheduled
  ['TBD', 'scheduled'],
  ['NS', 'scheduled'],

  // live
  ['1H', 'live'],
  ['HT', 'live'],
  ['2H', 'live'],
  ['ET', 'live'],
  ['BT', 'live'],
  ['P', 'live'],
  ['SUSP', 'live'],
  ['INT', 'live'],
  ['LIVE', 'live'],

  // finished
  ['FT', 'finished'],
  ['AET', 'finished'],
  ['PEN', 'finished'],

  // postponed
  ['PST', 'postponed'],

  // cancelled
  ['CANC', 'cancelled'],
  ['ABD', 'cancelled'],
  ['AWD', 'cancelled'],
  ['WO', 'cancelled'],

  // conservative unknown fallback
  ['UNKNOWN_TEST_CODE', 'scheduled'],
];

function checkMapping(short, expected) {
  const actual = mapFootballStatus(short);
  const pass = actual === expected;
  const status = pass ? 'PASS' : 'FAIL';
  console.log(`[${status}] ${short} -> ${actual} (expected: ${expected})`);
  return pass;
}

function main() {
  console.log('[verify:football-status-mapping] Verifying API-SPORTS football status mapping...');
  const allPassed = EXPECTED_MAPPINGS
    .map(([short, expected]) => checkMapping(short, expected))
    .every(Boolean);

  console.log('\n' + (allPassed ?
    '✅ Football status mapping checks PASSED.' :
    '❌ One or more football status mapping checks FAILED.'));
  process.exit(allPassed ? 0 : 1);
}

main();
