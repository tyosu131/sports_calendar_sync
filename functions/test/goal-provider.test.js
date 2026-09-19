'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const payload = require('./fixtures/goal/team-fixtures.json');
const { GoalApiClient, GoalApiError } = require('../lib/providers/goal/goalApiClient');
const { adaptGoalFixtureToGameDoc, UnsupportedGoalStatusError } = require('../lib/adapters/goalFootballAdapter');
const { stableGoalGameId, persistGoalWrites, syncGoalV1Fixtures } = require('../lib/pipelines/syncGoalV1');
const { V1_GOAL_MEMBERSHIPS } = require('../lib/config/v1GoalMemberships');
const { internalTeamIdForGoalTeam, v1TeamNameJa } = require('../lib/providers/goal/teamIdentity');
const { orchestrateGoalTeamFixtures } = require('../lib/providers/goal/syncOrchestrator');
const { V1_GOAL_MEMBERSHIP_BINDINGS, PENDING_GOAL_COMPETITION_EVIDENCE } = require('../lib/providers/goal/v1CompetitionBindings');

const fixture = () => structuredClone(payload.data[0]);
const context = {
  competitionKey: 'football_premier', competitionSeasonKey: 'football_premier_2026',
  leagueId: 'premier', homeTeamId: 'arsenal', awayTeamId: 'kawasaki_frontale',
  homeTeamNameJa: 'アーセナル', awayTeamNameJa: '川崎フロンターレ',
};
const membership = {
  competitionSeasonKey: 'football_premier_2026', competitionKey: 'football_premier', seasonYear: 2026,
  displayNameJa: 'Premier', membershipType: 'league', memberTeamIds: ['arsenal'],
  status: 'approved', seedable: true,
};
const binding = { membership, goalLeagueId: 'goal-premier', goalLeagueYear: '2026/2027', leagueId: 'premier' };

function envelope(data, pagination = { total: data.length, limit: 100, offset: 0, hasMore: false }) {
  return { success: true, teamId: 'x', data, pagination, source: 'goal' };
}

test('client parses live fixture fields with missing venue and non-paginated upcoming', async () => {
  const calls = [];
  const http = { get: async (url, config) => {
    calls.push({ url, config });
    return { data: url.endsWith('/upcoming') ? { success: true, teamId: 'x', data: [fixture()], count: 1, source: 'goal' } : payload };
  } };
  const client = new GoalApiClient('test-key', http, 3210);
  const fixtures = await client.fixtures('team/id');
  const upcoming = await client.upcoming('team/id');
  assert.equal(fixtures[0].leagueYear, '2026/2027');
  assert.equal(fixtures[0].venue, undefined);
  assert.equal(upcoming.length, 1);
  assert.deepEqual(calls.map(call => call.url), [
    'https://api.goal-api.com/v1/teams/team%2Fid/fixtures?limit=100&offset=0',
    'https://api.goal-api.com/v1/teams/team%2Fid/upcoming',
  ]);
  assert.deepEqual(calls[0].config, { headers: { Authorization: 'Bearer test-key' }, timeout: 3210 });
});

test('fixturesAll follows offsets, deduplicates IDs, and stops on hasMore false', async () => {
  const offsets = [];
  const one = fixture();
  const two = fixture(); two.id = 'fixture-2';
  const http = { get: async url => {
    const offset = Number(new URL(url).searchParams.get('offset')); offsets.push(offset);
    return { data: offset === 0
      ? envelope([one], { total: 2, limit: 1, offset: 0, hasMore: true })
      : envelope([one, two], { total: 2, limit: 1, offset: 1, hasMore: false }) };
  } };
  const fixtures = await new GoalApiClient('key', http).fixturesAll('x', 1);
  assert.deepEqual(offsets, [0, 1]);
  assert.deepEqual(fixtures.map(item => item.id), [one.id, two.id]);
});

test('fixturesAll rejects pagination without progress and maximum-page loops', async () => {
  const noProgress = new GoalApiClient('key', { get: async () => ({ data: envelope([], { total: 2, limit: 0, offset: 0, hasMore: true }) }) });
  await assert.rejects(noProgress.fixturesAll('x'), e => e instanceof GoalApiError && /no progress/.test(e.message));
  const endless = new GoalApiClient('key', { get: async url => {
    const offset = Number(new URL(url).searchParams.get('offset'));
    return { data: envelope([], { total: 999, limit: 1, offset, hasMore: true }) };
  } });
  await assert.rejects(endless.fixturesAll('x', 1, 2), e => e instanceof GoalApiError && /maximum pages/.test(e.message));
});

test('client classifies errors and rejects malformed fixture contracts', async () => {
  const rateLimited = new GoalApiClient('key', { get: async () => { const e = new Error('no'); e.response = { status: 429 }; throw e; } });
  await assert.rejects(rateLimited.fixtures('x'), e => e instanceof GoalApiError && e.kind === 'rate_limited');
  const malformed = new GoalApiClient('key', { get: async () => ({ data: envelope([{ id: 7 }]) }) });
  await assert.rejects(malformed.fixtures('x'), e => e.kind === 'invalid_response');
  const legacy = new GoalApiClient('key', { get: async () => ({ data: { fixtures: [fixture()] } }) });
  await assert.rejects(legacy.upcoming('x'), e => e.kind === 'invalid_response');
});

test('adapter applies venue then matchStadium fallback and accepts null stadium', () => {
  const missingVenue = fixture(); missingVenue.matchStadium = ' Emirates Stadium ';
  const stadiumGame = adaptGoalFixtureToGameDoc(missingVenue, context);
  assert.equal(stadiumGame.venue, ' Emirates Stadium ');
  assert.equal(stadiumGame.homeSourceTeamId, missingVenue.homeTeam.id);
  assert.equal(stadiumGame.awaySourceTeamId, missingVenue.awayTeam.id);
  const preferred = fixture(); preferred.venue = 'Provider Venue'; preferred.matchStadium = 'Fallback';
  assert.equal(adaptGoalFixtureToGameDoc(preferred, context).venue, 'Provider Venue');
  const nullStadium = fixture(); nullStadium.matchStadium = null;
  assert.equal(adaptGoalFixtureToGameDoc(nullStadium, context).venue, undefined);
});

test('adapter maps every supported lifecycle status and stable identity ignores mutable fields', () => {
  const input = fixture();
  const first = adaptGoalFixtureToGameDoc(input, context);
  const id = stableGoalGameId(input.id);
  input.kickoffUtc = '2026-09-21T15:30:00Z';
  assert.equal(adaptGoalFixtureToGameDoc(input, context).sourceFixtureId, first.sourceFixtureId);
  assert.equal(stableGoalGameId(input.id), id);
  const expected = { SCHEDULED: 'scheduled', LIVE: 'live', HALF_TIME: 'live', FINISHED: 'finished',
    AFTER_ET: 'finished', AFTER_PEN: 'finished', POSTPONED: 'postponed', CANCELLED: 'cancelled' };
  for (const [provider, canonical] of Object.entries(expected)) {
    input.matchStatus = provider;
    assert.equal(adaptGoalFixtureToGameDoc(input, context).status, canonical);
    assert.equal(stableGoalGameId(input.id), id);
  }
  for (const status of ['AWARDED', 'ABANDONED', 'SUSPENDED', 'FUTURE_VALUE']) {
    input.matchStatus = status;
    assert.throws(() => adaptGoalFixtureToGameDoc(input, context), UnsupportedGoalStatusError);
  }
});

test('GOAL IDs resolve only known stable internal teams', () => {
  assert.equal(internalTeamIdForGoalTeam('cmr7foowe2kf3rx06u6eu3rhl'), 'arsenal');
  assert.equal(internalTeamIdForGoalTeam('unknown'), undefined);
  assert.equal(v1TeamNameJa('kawasaki_frontale'), '川崎フロンターレ');
  assert.equal(v1TeamNameJa('arsenal'), 'アーセナル');
  assert.throws(() => v1TeamNameJa('unknown'), /Missing V1 Japanese display name/);
});

test('production default names localize both V1 targets and preserve an unmapped opponent name', async () => {
  const kawasaki = fixture();
  kawasaki.id = 'kawasaki-default-name';
  kawasaki.league.id = V1_GOAL_MEMBERSHIP_BINDINGS[0].goalLeagueId;
  kawasaki.leagueYear = V1_GOAL_MEMBERSHIP_BINDINGS[0].goalLeagueYear;
  kawasaki.homeTeam = { id: 'cmr7be2nq0qkwrx06zxbqr5ux', name: 'Kawasaki Frontale' };
  kawasaki.awayTeam = { id: 'unmapped-j1-opponent', name: 'Provider J1 Opponent' };

  const arsenal = fixture();
  arsenal.id = 'arsenal-default-name';
  arsenal.league.id = V1_GOAL_MEMBERSHIP_BINDINGS[3].goalLeagueId;
  arsenal.leagueYear = V1_GOAL_MEMBERSHIP_BINDINGS[3].goalLeagueYear;
  arsenal.homeTeam = { id: 'cmr7foowe2kf3rx06u6eu3rhl', name: 'Arsenal' };
  arsenal.awayTeam = { id: 'unmapped-premier-opponent', name: 'Provider Premier Opponent' };

  const games = [];
  const persistence = { gameRef: id => id, newBatch: () => ({
    set: (_ref, game) => games.push(game), delete: () => {}, commit: async () => {},
  }) };
  const byProviderTeam = new Map([
    ['cmr7be2nq0qkwrx06zxbqr5ux', [kawasaki]],
    ['cmr7foowe2kf3rx06u6eu3rhl', [arsenal]],
  ]);

  await syncGoalV1Fixtures('test', {
    source: { fixtures: async teamId => structuredClone(byProviderTeam.get(teamId) ?? []) },
    persistence,
    // Deliberately omit `names`: this exercises the production resolver.
    targets: ['kawasaki_frontale', 'arsenal'],
  });

  const kawasakiGame = games.find(game => game.sourceFixtureId === kawasaki.id);
  const arsenalGame = games.find(game => game.sourceFixtureId === arsenal.id);
  assert.equal(kawasakiGame.homeTeamNameJa, '川崎フロンターレ');
  assert.equal(kawasakiGame.awayTeamNameJa, 'Provider J1 Opponent');
  assert.equal(arsenalGame.homeTeamNameJa, 'アーセナル');
  assert.equal(arsenalGame.awayTeamNameJa, 'Provider Premier Opponent');
});

test('known target with unknown opponent produces a Game with provider participant identity', async () => {
  const input = fixture(); input.awayTeam = { id: 'unknown-opponent', name: 'Opponent FC' };
  const result = await orchestrateGoalTeamFixtures({ fixtures: async () => [input] }, 'arsenal', [binding], { nameJa: id => id }, () => new Date('2026-09-19T00:00:00Z'));
  assert.equal(result.games.length, 1);
  assert.equal(result.games[0].homeTeamId, 'arsenal');
  assert.equal(result.games[0].awayTeamId, undefined);
  assert.equal(result.games[0].awaySourceTeamId, 'unknown-opponent');
  assert.equal(result.games[0].awayTeamNameJa, 'Opponent FC');
});

test('orchestration is season-aware, competition-aware, target-aware, and membership-aware', async () => {
  const wrongSeason = fixture(); wrongSeason.id = 'wrong-season'; wrongSeason.leagueYear = '2025/2026';
  const unknownCompetition = fixture(); unknownCompetition.id = 'unknown-competition'; unknownCompetition.league.id = 'other';
  const wrongTarget = fixture(); wrongTarget.id = 'wrong-target'; wrongTarget.homeTeam.id = 'other';
  const result = await orchestrateGoalTeamFixtures({ fixtures: async () => [fixture(), wrongSeason, unknownCompetition, wrongTarget] }, 'arsenal', [binding], { nameJa: id => id });
  assert.equal(result.games.length, 1);
  assert.deepEqual(result.skipped, [
    { fixtureId: 'wrong-season', reason: 'unknown_competition' },
    { fixtureId: 'unknown-competition', reason: 'unknown_competition' },
    { fixtureId: 'wrong-target', reason: 'unknown_team' },
  ]);
  const unapproved = { ...binding, membership: { ...membership, status: 'review' } };
  const denied = await orchestrateGoalTeamFixtures({ fixtures: async () => [fixture()] }, 'arsenal', [unapproved], { nameJa: id => id });
  assert.equal(denied.skipped[0].reason, 'unapproved_membership');
  assert.deepEqual(await orchestrateGoalTeamFixtures({ fixtures: async () => { throw new Error('must not fetch'); } }, 'unknown', [], { nameJa: id => id }), { games: [], skipped: [] });
});

test('future active/finished is anomalous while future cancelled and postponed are accepted', async () => {
  const finished = fixture(); finished.id = 'future-finished'; finished.matchStatus = 'FINISHED';
  const cancelled = fixture(); cancelled.id = 'future-cancelled'; cancelled.matchStatus = 'CANCELLED';
  const postponed = fixture(); postponed.id = 'future-postponed'; postponed.matchStatus = 'POSTPONED';
  const result = await orchestrateGoalTeamFixtures({ fixtures: async () => [finished, cancelled, postponed] }, 'arsenal', [binding], { nameJa: id => id }, () => new Date('2026-09-19T00:00:00Z'));
  assert.deepEqual(result.games.map(game => game.status), ['cancelled', 'postponed']);
  assert.deepEqual(result.skipped, [{ fixtureId: 'future-finished', reason: 'provider_data_anomaly' }]);
});

test('fresh write batches are used after chunk commits', async () => {
  const batches = [];
  const persistence = { gameRef: id => id, newBatch: () => {
    const batch = { committed: false, writes: [], set(ref) { assert.equal(this.committed, false); this.writes.push(ref); },
      delete() {}, async commit() { assert.equal(this.committed, false); this.committed = true; } };
    batches.push(batch); return batch;
  } };
  const game = adaptGoalFixtureToGameDoc(fixture(), context);
  await persistGoalWrites(persistence, Array.from({ length: 5 }, (_, i) => ({ kind: 'set', id: `${i}`, game })), 2);
  assert.deepEqual(batches.map(batch => batch.writes.length), [2, 2, 1]);
  assert.ok(batches.every(batch => batch.committed));
});

test('pipeline deduplicates cross-target fixture and unsupported state deletes stable document', async () => {
  const input = fixture();
  // Use real active binding identifiers so persistence boundary is exercised.
  input.league.id = V1_GOAL_MEMBERSHIP_BINDINGS[3].goalLeagueId;
  input.leagueYear = V1_GOAL_MEMBERSHIP_BINDINGS[3].goalLeagueYear;
  const writes = [];
  const persistence = { gameRef: id => id, newBatch: () => ({
    set: (ref, game, options) => writes.push({ kind: 'set', ref, game, options }),
    delete: ref => writes.push({ kind: 'delete', ref }), commit: async () => {},
  }) };
  const source = { fixtures: async () => [structuredClone(input)] };
  const summary = await syncGoalV1Fixtures('test', { source, persistence, targets: ['arsenal', 'arsenal'],
    names: { nameJa: id => id }, now: () => new Date('2026-09-19T00:00:00Z') });
  assert.equal(summary.duplicates, 1);
  assert.equal(writes.length, 1);
  assert.deepEqual(writes[0].options, { merge: true });
  writes.length = 0; input.matchStatus = 'AWARDED';
  await syncGoalV1Fixtures('test', { source, persistence, targets: ['arsenal'], names: { nameJa: id => id } });
  assert.deepEqual(writes, [{ kind: 'delete', ref: stableGoalGameId(input.id) }]);
});

test('V1 bindings contain approved observed seasons and leave FA Cup pending', () => {
  assert.equal(V1_GOAL_MEMBERSHIP_BINDINGS.length, 6);
  assert.ok(V1_GOAL_MEMBERSHIP_BINDINGS.every(item => item.goalLeagueYear && item.membership.seedable));
  assert.ok(!V1_GOAL_MEMBERSHIP_BINDINGS.some(item => item.goalLeagueId === PENDING_GOAL_COMPETITION_EVIDENCE.arsenalFaCupGoalLeagueId));
  assert.ok(!V1_GOAL_MEMBERSHIP_BINDINGS.some(item => ['cmr77dvkr005irx066wcuvzrh', 'cmr77dvhi003orx061j0awisx', 'cmr77dwv800nxrx065czxdl0q'].includes(item.goalLeagueId)));
  assert.equal(V1_GOAL_MEMBERSHIP_BINDINGS[0].membership, V1_GOAL_MEMBERSHIPS.j1);
  assert.deepEqual(V1_GOAL_MEMBERSHIPS.jLeagueCup.membershipType, 'cup');
  assert.deepEqual(V1_GOAL_MEMBERSHIPS.emperorCup.membershipType, 'cup');
  assert.deepEqual(V1_GOAL_MEMBERSHIPS.leagueCup.membershipType, 'cup');
});
