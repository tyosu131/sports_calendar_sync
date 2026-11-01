'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const fixtures = require('./fixtures/thesportsdb/events.json');
const { TheSportsDbClient, TsdbApiError, parseEvents, parseTeamColor } = require('../lib/providers/thesportsdb/client');
const {
  adaptTsdbEventToGameDoc, tsdbVenueOffsetMinutes, tsdbUtc, TsdbSkip, englishSearchKeywords,
} = require('../lib/adapters/theSportsDbAdapter');
const {
  syncTheSportsDb, upcomingEventRounds, nflSeason, ufcSeasons, nflRoundsToRead, TSDB_COMPETITIONS,
  UFC_CARDS_PER_RUN, TSDB_COLOR_LOOKUPS_PER_RUN,
} = require('../lib/pipelines/syncTheSportsDb');
const { presentCalendarGame } = require('../lib/calendar/eventPresentation');

const NFL = TSDB_COMPETITIONS.find((c) => c.competitionKey === 'americanfootball_nfl');
const UFC = TSDB_COMPETITIONS.find((c) => c.competitionKey === 'mma_ufc');
const event = (name, patch = {}) => ({ ...structuredClone(fixtures[name]), ...patch });
const NOW = new Date('2026-10-31T00:00:00Z');

test('client parses events, treats null as empty and retries a non-JSON body once', async () => {
  const bodies = ['<html>slow down</html>', JSON.stringify({ events: [fixtures.nfl] }), JSON.stringify({ events: null })];
  const urls = [];
  const sleeps = [];
  const client = new TheSportsDbClient('123', {
    get: async (url) => { urls.push(url); return { data: bodies.shift() }; },
  }, 0, 5, async (ms) => { sleeps.push(ms); });
  const events = await client.eventsRound('4391', 1, '2026');
  assert.equal(events.length, 1);
  assert.equal(events[0].strHomeTeam, 'Cincinnati Bengals');
  assert.equal(urls[0], 'https://www.thesportsdb.com/api/v1/json/123/eventsround.php?id=4391&r=1&s=2026');
  assert.deepEqual(sleeps, [5]);
  assert.deepEqual(await client.eventsRound('4391', 19, '2026'), []);
});

test('client rejects malformed events and surfaces repeated non-JSON', async () => {
  assert.throws(() => parseEvents({ events: [{ idEvent: 1 }] }), TsdbApiError);
  assert.throws(() => parseEvents({}), TsdbApiError);
  const client = new TheSportsDbClient('123', { get: async () => ({ data: 'nope' }) }, 0, 0, async () => {});
  await assert.rejects(client.eventsRound('4391', 1, '2026'), (error) => error.kind === 'invalid_response');
});

test('venue offset comes from the wall clock, not the unreliable local date', () => {
  const vegas = event('ufcVegas');
  assert.equal(tsdbVenueOffsetMinutes(tsdbUtc(vegas.strTimestamp), vegas.strTimeLocal), -8 * 60);
  // Sydney: provider local date says 01-31 but 22:00 UTC is 09:00 on 02-01 (+11).
  const sydney = event('ufcSydney');
  assert.equal(tsdbVenueOffsetMinutes(tsdbUtc(sydney.strTimestamp), sydney.strTimeLocal), 11 * 60);
  const canton = event('nflCanton');
  assert.equal(tsdbVenueOffsetMinutes(tsdbUtc(canton.strTimestamp), canton.strTimeLocal), -4 * 60);
  assert.equal(tsdbVenueOffsetMinutes(new Date('2026-01-01T00:00:00Z'), '12:00:00'), undefined);
  assert.equal(tsdbVenueOffsetMinutes(new Date('2026-01-01T00:00:00Z'), null), undefined);
});

test('NFL event becomes a two-team game with provider-id teams and scores', () => {
  const game = adaptTsdbEventToGameDoc(event('nfl'), NFL, '2026', NOW);
  assert.equal(game.homeTeamId, 'tsdb_team_134923');
  assert.equal(game.awayTeamId, 'tsdb_team_134939');
  assert.equal(game.homeTeamNameEn, 'Cincinnati Bengals');
  assert.equal(game.homeTeamNameJa, 'Cincinnati Bengals');
  assert.equal(game.competitionKey, 'americanfootball_nfl');
  assert.equal(game.competitionSeasonKey, 'americanfootball_nfl_2026');
  assert.equal(game.status, 'finished');
  assert.equal(game.homeScore, 16);
  assert.equal(game.awayScore, 14);
  assert.equal(game.venue, 'Paycor Stadium');
  assert.equal(game.venueUtcOffsetMinutes, -240);
  assert.equal(game.startTimeUTC.toDate().toISOString(), '2026-08-13T23:00:00.000Z');
  assert.equal(game.startTimeJST, '2026-08-14 08:00');
  assert.equal(game.sourceProvider, 'thesportsdb');
  assert.equal(game.sourceFixtureId, '2475337');
});

test('NFL status: live or unknown codes are skipped, flags win, scores need a final', () => {
  assert.throws(() => adaptTsdbEventToGameDoc(event('nfl', { strStatus: 'Q2' }), NFL, '2026', NOW),
    (error) => error instanceof TsdbSkip && error.reason === 'unsupported_status');
  const upcoming = adaptTsdbEventToGameDoc(event('nfl', { strStatus: 'NS', intHomeScore: null, intAwayScore: null }), NFL, '2026', NOW);
  assert.equal(upcoming.status, 'scheduled');
  assert.equal('homeScore' in upcoming, false);
  assert.equal(adaptTsdbEventToGameDoc(event('nfl', { strPostponed: 'yes' }), NFL, '2026', NOW).status, 'postponed');
  assert.throws(() => adaptTsdbEventToGameDoc(event('nfl', { idHomeTeam: null }), NFL, '2026', NOW), TsdbSkip);
  assert.throws(() => adaptTsdbEventToGameDoc(event('nfl', { strTimestamp: '2026-08-13' }), NFL, '2026', NOW), TsdbSkip);
});

test('UFC card is one titled game owned by the league follow item', () => {
  const game = adaptTsdbEventToGameDoc(event('ufcVegas'), UFC, '2026', NOW);
  assert.equal(game.homeTeamId, 'tsdb_league_4443');
  assert.equal(game.homeTeamNameEn, 'UFC 324 Gaethje vs Pimblett');
  assert.equal(game.awayTeamNameJa, '');
  assert.equal('awayTeamId' in game, false);
  // Provider leaves past cards at NS; the card is finished once it has started.
  assert.equal(game.status, 'finished');
  const future = adaptTsdbEventToGameDoc(event('ufcVegas', { strTimestamp: '2026-11-07T22:00:00' }), UFC, '2026', NOW);
  assert.equal(future.status, 'scheduled');
  assert.equal(presentCalendarGame({ homeTeamName: game.homeTeamNameEn, awayTeamName: '', status: 'scheduled' }).title,
    'UFC 324 Gaethje vs Pimblett');
});

function ufcSeason(dates) {
  // Card number N starts on dates[N-1]; anything past the list is empty.
  const calls = [];
  return {
    calls,
    eventsRound: async (_league, round) => {
      calls.push(round);
      const date = dates[round - 1];
      if (!date) return [];
      return [event('ufcVegas', { idEvent: `e${round}`, intRound: String(round), strEvent: `UFC ${round}`, strTimestamp: `${date}T22:00:00` })];
    },
  };
}

test('upcoming UFC cards are found without reading every past card', async () => {
  const dates = Array.from({ length: 60 }, (_, i) => new Date(Date.UTC(2026, 0, 3 + i * 6)).toISOString().slice(0, 10));
  const source = ufcSeason(dates);
  const from = new Date('2026-10-24T00:00:00Z');
  const events = await upcomingEventRounds(source, '4443', '2026', from);
  const firstExpected = dates.findIndex((d) => new Date(`${d}T22:00:00Z`) >= from) + 1;
  assert.equal(events[0].intRound, String(firstExpected));
  assert.equal(events.length, UFC_CARDS_PER_RUN);
  assert.equal(events.at(-1).intRound, String(firstExpected + UFC_CARDS_PER_RUN - 1));
  assert.ok(source.calls.length <= 7 + UFC_CARDS_PER_RUN + 1, `used ${source.calls.length} requests`);
});

test('upcoming UFC cards: empty season and all-future season', async () => {
  assert.deepEqual(await upcomingEventRounds(ufcSeason([]), '4443', '2026', NOW), []);
  const all = await upcomingEventRounds(ufcSeason(['2026-11-07', '2026-11-14']), '4443', '2026', NOW);
  assert.deepEqual(all.map((e) => e.intRound), ['1', '2']);
});

test('seasons: NFL January belongs to the previous year, UFC December reads ahead', () => {
  assert.equal(nflSeason(new Date('2027-01-20T00:00:00Z')), '2026');
  assert.equal(nflSeason(new Date('2026-09-01T00:00:00Z')), '2026');
  assert.deepEqual(ufcSeasons(new Date('2026-10-31T00:00:00Z')), ['2026']);
  assert.deepEqual(ufcSeasons(new Date('2026-12-15T00:00:00Z')), ['2026', '2027']);
});

test('sync upserts games and provider-id teams, filters side shows, never deletes', async () => {
  const writes = [];
  const persistence = {
    gameRef: (id) => ({ path: `games/${id}` }),
    teamRef: (id) => ({ path: `teams/${id}` }),
    newBatch: () => ({
      set: (ref, data, options) => writes.push({ path: ref.path, data, options }),
      delete: () => { throw new Error('must not delete'); },
      commit: async () => {},
    }),
  };
  const nflRounds = [];
  const source = {
    eventsRound: async (league, round) => {
      if (league === '4391') {
        nflRounds.push(round);
        return round === 1 ? [event('nfl', { strStatus: 'NS', intHomeScore: null, intAwayScore: null, strTimestamp: '2026-11-04T23:00:00' })] : [];
      }
      if (round === 1) return [event('ufcVegas', { strTimestamp: '2026-11-07T22:00:00' })];
      if (round === 2) return [event('ufcVegas', { idEvent: 'dwcs', strEvent: 'Dana Whites Contender Series season 10 Week 3', strTimestamp: '2026-11-10T00:00:00' })];
      return [];
    },
  };
  const summary = await syncTheSportsDb('123', { source, persistence, now: () => NOW });
  // Week 1 is read first; the rest is the window around the current week (before week 1 starts: weeks 2-4).
  assert.deepEqual(nflRounds, [1, 2, 3, 4]);
  const paths = writes.map((w) => w.path).sort();
  assert.deepEqual(paths, [
    'games/tsdb_2389036', 'games/tsdb_2475337',
    'teams/tsdb_league_4443', 'teams/tsdb_team_134923', 'teams/tsdb_team_134939',
  ]);
  assert.ok(writes.every((w) => w.options.merge === true));
  const bengals = writes.find((w) => w.path === 'teams/tsdb_team_134923').data;
  assert.equal(bengals.nameEn, 'Cincinnati Bengals');
  assert.equal(bengals.competitionKey, 'americanfootball_nfl');
  assert.ok(bengals.searchKeywords.includes('bengals'));
  assert.equal(writes.find((w) => w.path === 'teams/tsdb_league_4443').data.nameEn, 'UFC');
  assert.equal(summary.skipCounts.filtered_event, 1);
  assert.equal(summary.gamesUpserted, 2);
});

test('english search keywords cover phrase and word prefixes', () => {
  const keywords = englishSearchKeywords('Kansas City Chiefs');
  for (const value of ['k', 'kansas city chiefs', 'chi', 'chiefs', 'city']) assert.ok(keywords.includes(value), value);
});

test('429 waits for Retry-After, then succeeds; gives up after the retry limit', async () => {
  const throttled = () => Object.assign(new Error('429'), { response: { status: 429, headers: { 'retry-after': '45' } } });
  const queue = [throttled, () => ({ data: JSON.stringify({ events: [fixtures.nfl] }) })];
  const sleeps = [];
  const logs = [];
  const client = new TheSportsDbClient('123', {
    get: async () => { const next = queue.shift()(); if (next instanceof Error) throw next; return next; },
  }, 0, 10, async (ms) => { sleeps.push(ms); }, 1000, 3, (message, detail) => logs.push({ message, detail }));
  assert.equal((await client.eventsRound('4391', 1, '2026')).length, 1);
  assert.deepEqual(sleeps, [45_000]);
  assert.equal(logs[0].detail.retryAfterSeconds, 45);

  let calls = 0;
  const always = new TheSportsDbClient('123', { get: async () => { calls += 1; throw throttled(); } },
    0, 10, async () => {}, 1000, 2, () => {});
  await assert.rejects(always.eventsRound('4391', 1, '2026'), (error) => error.kind === 'rate_limited');
  assert.equal(calls, 3);
});

test('a throttled NFL week is reported but the other weeks are still saved', async () => {
  const writes = [];
  const persistence = {
    gameRef: (id) => ({ path: `games/${id}` }),
    teamRef: (id) => ({ path: `teams/${id}` }),
    newBatch: () => ({ set: (ref) => writes.push(ref.path), commit: async () => {} }),
  };
  const source = {
    eventsRound: async (league, round) => {
      if (league === '4391' && round === 2) throw new TsdbApiError('rate_limited', 'limit', 429);
      if (league === '4391' && round === 1) return [event('nfl', { strStatus: 'NS', intHomeScore: null, intAwayScore: null, strTimestamp: '2026-11-04T23:00:00' })];
      return [];
    },
  };
  const summary = await syncTheSportsDb('123', { source, persistence, now: () => NOW });
  assert.deepEqual(summary.failedRounds, ['americanfootball_nfl:2026:2']);
  assert.ok(writes.includes('games/tsdb_2475337'));
});

test('NFL weeks to read follow the calendar from week 1', () => {
  const weekOne = new Date('2026-09-10T00:20:00Z');
  assert.deepEqual(nflRoundsToRead(weekOne, new Date('2026-08-20T00:00:00Z')), [1, 2, 3, 4]);
  assert.deepEqual(nflRoundsToRead(weekOne, new Date('2026-11-01T00:00:00Z')), [7, 8, 9, 10, 11]);
  assert.deepEqual(nflRoundsToRead(weekOne, new Date('2027-01-05T00:00:00Z')), [16, 17, 18]);
  assert.deepEqual(nflRoundsToRead(weekOne, new Date('2027-02-01T00:00:00Z')), [17, 18]);
});

test('each competition is saved as soon as it is read, even if the next one fails', async () => {
  const committed = [];
  const persistence = {
    gameRef: (id) => ({ path: `games/${id}` }),
    teamRef: (id) => ({ path: `teams/${id}` }),
    newBatch: () => ({ set: () => {}, commit: async () => { committed.push(true); } }),
  };
  const source = {
    eventsRound: async (league, round) => {
      if (league === '4391') return round === 1
        ? [event('nfl', { strStatus: 'NS', intHomeScore: null, intAwayScore: null, strTimestamp: '2026-11-04T23:00:00' })] : [];
      throw new TsdbApiError('rate_limited', 'limit', 429);
    },
  };
  const summary = await syncTheSportsDb('123', { source, persistence, now: () => NOW });
  assert.equal(committed.length, 2); // NFL batch, then the UFC follow item.
  assert.deepEqual(summary.failedRounds, ['mma_ufc:2026']);
  assert.equal(summary.gamesUpserted, 1);
});

test('a retry wait that would pass the deadline is not taken', async () => {
  const sleeps = [];
  const client = new TheSportsDbClient('123', {
    get: async () => { throw Object.assign(new Error('429'), { response: { status: 429, headers: { 'retry-after': '120' } } }); },
  }, 0, 10, async (ms) => { sleeps.push(ms); }, 1000, 3, () => {});
  client.setDeadline(Date.now() + 60_000);
  await assert.rejects(client.eventsRound('4391', 1, '2026'), (error) => error.kind === 'rate_limited');
  assert.deepEqual(sleeps, []);
});

test('team color parsing keeps only a #RRGGBB primary color', () => {
  assert.deepEqual(parseTeamColor({ teams: [{ idTeam: '134923', strColour1: '#fb4f14', strColour2: '#000000' }] }),
    { idTeam: '134923', primaryColor: '#FB4F14' });
  assert.deepEqual(parseTeamColor({ teams: [{ idTeam: '1', strColour1: 'orange' }] }), { idTeam: '1' });
  assert.deepEqual(parseTeamColor({ teams: [{ idTeam: '1', strColour1: null }] }), { idTeam: '1' });
  assert.equal(parseTeamColor({ teams: null }), undefined);
  assert.throws(() => parseTeamColor({}), TsdbApiError);
});

test('team colors are looked up for teams without one, a few per run, and saved with merge', async () => {
  const writes = [];
  const lookups = [];
  const stored = new Set(['tsdb_team_134923']); // already has a color
  const persistence = {
    gameRef: (id) => ({ path: `games/${id}` }),
    teamRef: (id) => ({ path: `teams/${id}` }),
    newBatch: () => ({ set: (ref, data, options) => writes.push({ path: ref.path, data, options }), commit: async () => {} }),
    teamsWithoutColor: async (ids) => ids.filter((id) => !stored.has(id)),
  };
  const source = {
    eventsRound: async (league, round) => {
      if (league !== '4391' || round !== 1) return [];
      return Array.from({ length: 12 }, (_, i) => event('nfl', {
        idEvent: `e${i}`, idHomeTeam: String(134900 + i), idAwayTeam: String(134923 + (i === 0 ? 0 : 100 + i)),
        strHomeTeam: `Home ${i}`, strAwayTeam: `Away ${i}`, strStatus: 'NS', intHomeScore: null, intAwayScore: null,
        strTimestamp: '2026-11-04T23:00:00',
      }));
    },
    lookupTeamColor: async (id) => { lookups.push(id); return { idTeam: id, primaryColor: '#112233' }; },
  };
  const summary = await syncTheSportsDb('123', { source, persistence, now: () => NOW, competitions: [NFL] });
  assert.equal(lookups.length, TSDB_COLOR_LOOKUPS_PER_RUN);
  assert.ok(!lookups.includes('134923'));
  assert.equal(summary.colorsSaved, TSDB_COLOR_LOOKUPS_PER_RUN);
  const colorWrites = writes.filter((w) => w.data.presentationColor);
  assert.equal(colorWrites.length, TSDB_COLOR_LOOKUPS_PER_RUN);
  assert.ok(colorWrites.every((w) => w.options.merge === true && w.path.startsWith('teams/tsdb_team_')));
  assert.deepEqual(Object.keys(colorWrites[0].data), ['presentationColor']);
});
