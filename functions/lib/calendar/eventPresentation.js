"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.presentCalendarGame = presentCalendarGame;
/** The provider-independent presentation shared by ICS and direct API adapters. */
function presentCalendarGame(game) {
    const scoreIsAuthoritative = game.status === "finished" &&
        Number.isInteger(game.homeScore) && Number.isInteger(game.awayScore) &&
        game.homeScore >= 0 && game.awayScore >= 0;
    // An event card (e.g. UFC) has one title and no away side.
    const matchup = game.awayTeamName.trim() === ""
        ? game.homeTeamName
        : scoreIsAuthoritative
            ? `${game.homeTeamName} ${game.homeScore}-${game.awayScore} ${game.awayTeamName}`
            : `${game.homeTeamName} vs ${game.awayTeamName}`;
    return {
        title: `${game.competitionCompact ? `[${game.competitionCompact}] ` : ""}${matchup}`,
        ...(game.venue ? { venue: game.venue } : {}),
        status: game.status,
    };
}
//# sourceMappingURL=eventPresentation.js.map