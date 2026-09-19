/** Shared validation and Firestore serialization for competition team masters. */

'use strict';

const { generateSearchKeywords } = require('./searchKeywords');

function validateTeam(team) {
  const requiredFields = ['id', 'nameJa', 'nameEn', 'aliases', 'source'];

  for (const field of requiredFields) {
    if (team[field] === undefined || team[field] === null || team[field] === '') {
      throw new Error(`Missing required field "${field}" for team: ${team.id || '(unknown)'}`);
    }
  }

  if (!Array.isArray(team.aliases)) {
    throw new Error(`aliases must be an array for team: ${team.id}`);
  }
  if (team.externalTeamId !== undefined && typeof team.externalTeamId !== 'number') {
    throw new Error(`externalTeamId must be a number when present for team: ${team.id}`);
  }
  if (team.logoUrl !== undefined && (typeof team.logoUrl !== 'string' || team.logoUrl === '')) {
    throw new Error(`logoUrl must be a non-empty string when present for team: ${team.id}`);
  }
  if (team.status !== 'confirmed') {
    throw new Error(`teams must contain confirmed teams only. Move unconfirmed team "${team.id}" to teamsTodo.`);
  }
}

function validateTeamsArray(teams) {
  for (const team of teams) validateTeam(team);
}

function toTeamDoc({ competition, team }) {
  return {
    nameJa: team.nameJa,
    nameEn: team.nameEn,
    searchKeywords: generateSearchKeywords({
      nameJa: team.nameJa,
      nameEn: team.nameEn,
      aliases: team.aliases,
    }),
    leagueId: competition.leagueId,
    country: competition.country,
    competitionKey: competition.competitionKey,
    sportKey: competition.competitionKey,
    sportType: competition.sportType,
    dataSourceKey: competition.dataSourceKey,
    ...(team.externalTeamId !== undefined
      ? { externalTeamId: team.externalTeamId, rapidApiId: team.externalTeamId }
      : {}),
    ...(team.logoUrl !== undefined ? { logoUrl: team.logoUrl } : {}),
  };
}

module.exports = { toTeamDoc, validateTeam, validateTeamsArray };
