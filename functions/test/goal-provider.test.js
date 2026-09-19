'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const payload = require('./fixtures/goal/team-fixtures.json');
const { GoalApiClient, GoalApiError } = require('../lib/providers/goal/goalApiClient');
const { adaptGoalFixtureToGameDoc, UnsupportedGoalStatusError } = require('../lib/adapters/goalFootballAdapter');
const { internalTeamIdForGoalTeam } = require('../lib/providers/goal/teamIdentity');
const { orchestrateGoalTeamFixtures } = require('../lib/providers/goal/syncOrchestrator');

const fixture = () => structuredClone(payload.data[0]);
const context = {
  competitionKey: 'football_premier', competitionSeasonKey: 'football_premier_2026',
  leagueId: 'premier', homeTeamId: 'arsenal', awayTeamId: 'kawasaki_frontale',
  homeTeamNameJa: 'アーセナル', awayTeamNameJa: '川崎フロンターレ',
};

test('client constructs authenticated Team requests and parses string IDs', async () => {
  const calls = [];
  const http = { get: async (url, config) => { calls.push({ url, config }); return { data: payload }; } };
  const client = new GoalApiClient('test-key', http, 3210);
  const fixtures = await client.fixtures('team/id');
  await client.upcoming('team/id');
  assert.equal(fixtures[0].id, 'goal-fixture-premier-1');
  assert.deepEqual(calls, [
    { url: 'https://api.goal-api.com/v1/teams/team%2Fid/fixtures', config: { headers: { Authorization: 'Bearer test-key' }, timeout: 3210 } },
    { url: 'https://api.goal-api.com/v1/teams/team%2Fid/upcoming', config: { headers: { Authorization: 'Bearer test-key' }, timeout: 3210 } },
  ]);
});

test('client classifies 429 and malformed documented envelopes', async () => {
  const rateLimited = new GoalApiClient('key', { get: async () => { const e = new Error('no'); e.response = { status: 429 }; throw e; } });
  await assert.rejects(rateLimited.fixtures('x'), (e) => e instanceof GoalApiError && e.kind === 'rate_limited' && e.status === 429);
  const malformed = new GoalApiClient('key', { get: async () => ({ data: { success: true, data: [{ id: 7 }] } }) });
  await assert.rejects(malformed.fixtures('x'), (e) => e.kind === 'invalid_response');
  const unsuccessful = new GoalApiClient('key', { get: async () => ({ data: { success: false, data: [] } }) });
  await assert.rejects(unsuccessful.fixtures('x'), (e) => e.kind === 'invalid_response');
});

test('client rejects the legacy fixtures envelope without documented data', async () => {
  const legacyEnvelope = { fixtures: structuredClone(payload.data) };
  const client = new GoalApiClient('key', { get: async () => ({ data: legacyEnvelope }) });
  await assert.rejects(client.fixtures('x'),
    (e) => e instanceof GoalApiError && e.kind === 'invalid_response');
});

test('adapter maps SCHEDULED, null venue, string identity and does not mutate input', () => {
  const input = fixture();
  const before = structuredClone(input);
  const game = adaptGoalFixtureToGameDoc(input, context);
  assert.equal(game.sourceProvider, 'goal');
  assert.equal(game.sourceFixtureId, input.id);
  assert.equal(game.startTimeUTC.toDate().toISOString(), '2026-09-20T15:30:00.000Z');
  assert.equal(game.status, 'scheduled');
  assert.equal(game.venue, undefined);
  assert.equal(game.homeTeamLogoUrl, undefined);
  assert.deepEqual(input, before);
});

test('kickoff changes preserve source identity and unsupported status fails explicitly', () => {
  const input = fixture();
  const first = adaptGoalFixtureToGameDoc(input, context);
  input.kickoffUtc = '2026-09-21T15:30:00Z';
  const moved = adaptGoalFixtureToGameDoc(input, context);
  assert.equal(moved.sourceFixtureId, first.sourceFixtureId);
  input.matchStatus = 'POSTPONED';
  assert.throws(() => adaptGoalFixtureToGameDoc(input, context), UnsupportedGoalStatusError);
});

test('GOAL IDs resolve to stable, competition-neutral team IDs', () => {
  assert.equal(internalTeamIdForGoalTeam('cmr7foowe2kf3rx06u6eu3rhl'), 'arsenal');
  assert.equal(internalTeamIdForGoalTeam('cmr7be2nq0qkwrx06zxbqr5ux'), 'kawasaki_frontale');
  assert.equal(internalTeamIdForGoalTeam('unknown'), undefined);
});

test('orchestration includes approved membership and fails closed otherwise', async () => {
  const unknownTeam = fixture(); unknownTeam.id = 'unknown-team'; unknownTeam.awayTeam.id = 'not-mapped';
  const unsupported = fixture(); unsupported.id = 'unsupported-status'; unsupported.matchStatus = 'LIVE';
  const unknownCompetition = fixture(); unknownCompetition.id = 'unknown-competition'; unknownCompetition.league.id = 'not-configured';
  const source = { fixtures: async () => [...structuredClone(payload.data), unknownCompetition, unknownTeam, unsupported] };
  const membership = {
    competitionSeasonKey: 'football_premier_2026', competitionKey: 'football_premier', seasonYear: 2026,
    displayNameJa: 'Premier', membershipType: 'league', memberTeamIds: ['arsenal', 'kawasaki_frontale'],
    status: 'approved', seedable: true,
  };
  const result = await orchestrateGoalTeamFixtures(source, 'arsenal', [
    { membership, goalLeagueId: 'goal-premier', leagueId: 'premier' },
    { membership: { ...membership, competitionSeasonKey: 'friendly_2026', status: 'review' }, goalLeagueId: 'goal-friendly', leagueId: 'friendly' },
  ], { nameJa: (id) => id });
  assert.equal(result.games.length, 1);
  assert.equal(result.games[0].sourceFixtureId, 'goal-fixture-premier-1');
  assert.deepEqual(result.skipped, [
    { fixtureId: 'goal-fixture-friendly-1', reason: 'unapproved_membership' },
    { fixtureId: 'unknown-competition', reason: 'unknown_competition' },
    { fixtureId: 'unknown-team', reason: 'unknown_team' },
    { fixtureId: 'unsupported-status', reason: 'unsupported_status' },
  ]);
  assert.deepEqual(await orchestrateGoalTeamFixtures(source, 'not-supported', [], { nameJa: id => id }), { games: [], skipped: [] });
});
