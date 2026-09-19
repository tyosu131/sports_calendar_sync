'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const payload = require('./fixtures/goal/team-fixtures.json');
const { GoalApiClient, GoalApiError } = require('../lib/providers/goal/goalApiClient');
const { adaptGoalFixtureToGameDoc, UnsupportedGoalStatusError } = require('../lib/adapters/goalFootballAdapter');
const { internalTeamIdForGoalTeam } = require('../lib/providers/goal/teamIdentity');
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

test('adapter preserves identity across kickoff changes and only maps SCHEDULED', () => {
  const input = fixture();
  const first = adaptGoalFixtureToGameDoc(input, context);
  input.kickoffUtc = '2026-09-21T15:30:00Z';
  assert.equal(adaptGoalFixtureToGameDoc(input, context).sourceFixtureId, first.sourceFixtureId);
  input.matchStatus = 'FINISHED';
  assert.throws(() => adaptGoalFixtureToGameDoc(input, context), UnsupportedGoalStatusError);
});

test('GOAL IDs resolve only known stable internal teams', () => {
  assert.equal(internalTeamIdForGoalTeam('cmr7foowe2kf3rx06u6eu3rhl'), 'arsenal');
  assert.equal(internalTeamIdForGoalTeam('unknown'), undefined);
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

test('future FINISHED is a provider anomaly while future SCHEDULED is accepted', async () => {
  const finished = fixture(); finished.id = 'future-finished'; finished.matchStatus = 'FINISHED';
  const result = await orchestrateGoalTeamFixtures({ fixtures: async () => [finished, fixture()] }, 'arsenal', [binding], { nameJa: id => id }, () => new Date('2026-09-19T00:00:00Z'));
  assert.equal(result.games.length, 1);
  assert.deepEqual(result.skipped, [{ fixtureId: 'future-finished', reason: 'provider_data_anomaly' }]);
});

test('V1 bindings contain approved observed seasons and leave FA Cup pending', () => {
  assert.equal(V1_GOAL_MEMBERSHIP_BINDINGS.length, 6);
  assert.ok(V1_GOAL_MEMBERSHIP_BINDINGS.every(item => item.goalLeagueYear && item.membership.seedable));
  assert.ok(!V1_GOAL_MEMBERSHIP_BINDINGS.some(item => item.goalLeagueId === PENDING_GOAL_COMPETITION_EVIDENCE.arsenalFaCupGoalLeagueId));
  assert.ok(!V1_GOAL_MEMBERSHIP_BINDINGS.some(item => ['cmr77dvkr005irx066wcuvzrh', 'cmr77dvhi003orx061j0awisx', 'cmr77dwv800nxrx065czxdl0q'].includes(item.goalLeagueId)));
});
