"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CalendarTeamNotFollowedError = exports.CalendarUserNotFoundError = exports.CalendarFeedNotFoundError = void 0;
exports.buildPersonalizedCalendar = buildPersonalizedCalendar;
const icsBuilder_1 = require("./icsBuilder");
class CalendarFeedNotFoundError extends Error {
}
exports.CalendarFeedNotFoundError = CalendarFeedNotFoundError;
class CalendarUserNotFoundError extends Error {
}
exports.CalendarUserNotFoundError = CalendarUserNotFoundError;
class CalendarTeamNotFollowedError extends Error {
}
exports.CalendarTeamNotFollowedError = CalendarTeamNotFollowedError;
function uniqueNonEmpty(values) {
    return [...new Set(values.filter((value) => typeof value === "string" && value.trim().length > 0))];
}
/**
 * Resolves the public feed credential to its owner, applies canonical team
 * membership, and renders only normalized games involving those teams.
 */
async function buildPersonalizedCalendar(repository, token, requestedTeamId) {
    const feed = await repository.findFeed(token);
    if (!feed?.active)
        throw new CalendarFeedNotFoundError("Calendar feed not found");
    const user = await repository.findUser(feed.ownerUid);
    if (!user)
        throw new CalendarUserNotFoundError("Calendar owner not found");
    let teamIds = uniqueNonEmpty(user.followedTeamIds);
    if (requestedTeamId) {
        if (!teamIds.includes(requestedTeamId)) {
            throw new CalendarTeamNotFollowedError("Team is not followed by calendar owner");
        }
        teamIds = [requestedTeamId];
    }
    if (teamIds.length === 0)
        return (0, icsBuilder_1.buildCalendar)([]);
    const allowed = new Set(teamIds);
    const games = await repository.findCalendarGamesForTeams(teamIds);
    // Repository queries are an optimization, never an authorization boundary.
    // Reapply membership here so an over-broad adapter cannot leak fixtures.
    return (0, icsBuilder_1.buildCalendar)(games.filter((game) => (game.homeTeamId !== undefined && allowed.has(game.homeTeamId)) ||
        (game.awayTeamId !== undefined && allowed.has(game.awayTeamId))));
}
//# sourceMappingURL=personalizedCalendar.js.map