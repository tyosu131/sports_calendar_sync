'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const search = require('./fixtures/thesportsdb/team-search.json');
const { parseTeamInfos, parseTeamColor } = require('../lib/providers/thesportsdb/client');
const {
  syncTeamColors, matchingTeam, TEAM_COLOR_SCOPES, TEAM_COLOR_LOOKUPS_PER_RUN,
} = require('../lib/pipelines/syncTeamColors');

const NOW = new Date('2026-11-01T00:00:00Z');
const jScope = TEAM_COLOR_SCOPES.football_j1;

test('provider search results keep a color only when it is #RRGGBB', () => {
  assert.equal(parseTeamInfos(search.kawasaki)[0].primaryColor, undefined);
  assert.equal(parseTeamInfos(search.arsenal)[0].primaryColor, '#EF0107');
  assert.deepEqual(parseTeamInfos({ teams: null }), []);
  assert.deepEqual(parseTeamInfos({ teams: [{ idTeam: 1 }] }), []);
  assert.equal(parseTeamColor(search.bengals).primaryColor, '#FB4F14');
});

test('a team matches only on sport, country and exact name', () => {
  const kawasaki = parseTeamInfos(search.kawasaki);
  assert.equal(matchingTeam(kawasaki, 'Kawasaki Frontale', jScope).idTeam, '137709');
  assert.equal(matchingTeam(kawasaki, 'Kawasaki Frontale', { sport: 'Soccer', country: 'England' }), undefined);
  assert.equal(matchingTeam(kawasaki, 'Kawasaki', jScope), undefined);
  assert.equal(matchingTeam(parseTeamInfos(search.arsenal), 'Arsenal', TEAM_COLOR_SCOPES.football_premier).primaryColor, '#EF0107');
  assert.equal(matchingTeam(parseTeamInfos(search.japan), 'Japan', jScope).idTeam, '134503');
  assert.equal(matchingTeam([], 'Arsenal', jScope), undefined);
});

function fakeStore(targets) {
  const updates = [];
  return {
    updates,
    targets: async () => targets,
    update: async (id, fields) => { updates.push({ id, fields }); },
  };
}

test('colors are saved when found; a club with no provider color is marked checked, not guessed', async () => {
  const store = fakeStore([
    { id: 'tsdb_team_134923', nameEn: 'Cincinnati Bengals', competitionKey: 'americanfootball_nfl', sourceTeamId: '134923' },
    { id: 'arsenal', nameEn: 'Arsenal', competitionKey: 'football_premier' },
    { id: 'kawasaki_frontale', nameEn: 'Kawasaki Frontale', competitionKey: 'football_j1' },
    { id: 'unknown_fc', nameEn: 'Nobody FC', competitionKey: 'football_j1' },
  ]);
  const searches = [];
  const source = {
    lookupTeamColor: async (id) => (id === '134923' ? parseTeamColor(search.bengals) : undefined),
    searchTeams: async (name) => {
      searches.push(name);
      if (name === 'Arsenal') return parseTeamInfos(search.arsenal);
      if (name === 'Kawasaki Frontale') return parseTeamInfos(search.kawasaki);
      return [];
    },
  };
  const summary = await syncTeamColors('123', { source, persistence: store, now: () => NOW });
  assert.deepEqual(summary, {
    looked: 4, colorsSaved: 2, noColor: 2, failed: [],
    noColorTeams: ['kawasaki_frontale (Kawasaki Frontale)', 'unknown_fc (Nobody FC)'],
  });
  const byId = Object.fromEntries(store.updates.map((u) => [u.id, u.fields]));
  assert.equal(byId.tsdb_team_134923.presentationColor, '#FB4F14');
  assert.equal(byId.tsdb_team_134923.presentationColorSource, 'thesportsdb:134923');
  assert.equal(byId.arsenal.presentationColor, '#EF0107');
  assert.equal('presentationColor' in byId.kawasaki_frontale, false);
  assert.equal(byId.kawasaki_frontale.presentationColorCheckedAt, NOW.toISOString());
  assert.equal('presentationColor' in byId.unknown_fc, false);
});

test('a run is limited and stops at the first provider failure, keeping what it saved', async () => {
  const many = Array.from({ length: 30 }, (_, i) => ({ id: `t${i}`, nameEn: `Team ${i}`, competitionKey: 'football_j1' }));
  const store = fakeStore(many);
  let calls = 0;
  const source = { searchTeams: async () => {
    calls += 1;
    if (calls === 3) throw new Error('throttled');
    return [];
  } };
  const summary = await syncTeamColors('123', { source, persistence: store, now: () => NOW });
  assert.equal(calls, 3);
  assert.deepEqual(summary.failed, ['t2']);
  assert.equal(store.updates.length, 2);

  const calm = fakeStore(many);
  let n = 0;
  await syncTeamColors('123', { source: { searchTeams: async () => { n += 1; return []; } }, persistence: calm, now: () => NOW });
  assert.equal(n, TEAM_COLOR_LOOKUPS_PER_RUN);
});

test('teams outside the color scopes are ignored', async () => {
  const store = fakeStore([{ id: 'x', nameEn: 'X', competitionKey: 'baseball_npb' }]);
  const summary = await syncTeamColors('123', { source: { searchTeams: async () => { throw new Error('no'); } }, persistence: store, now: () => NOW });
  assert.equal(summary.looked, 0);
  assert.equal(store.updates.length, 0);
});
