"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.competitionSeasonProfiles = exports.CURRENT_J1_COMPETITION_SEASON_KEY = void 0;
exports.findCompetitionSeasonProfileForLeague = findCompetitionSeasonProfileForLeague;
exports.CURRENT_J1_COMPETITION_SEASON_KEY = "football_j1_2026_hyakunen";
exports.competitionSeasonProfiles = [
    {
        competitionKey: "football_j1",
        competitionSeasonKey: exports.CURRENT_J1_COMPETITION_SEASON_KEY,
        displayNameJa: "明治安田Ｊ１百年構想リーグ",
        displayNameEn: "MEIJI YASUDA J1 100 YEAR VISION LEAGUE",
        externalLeagueId: 98,
        apiSeason: 2026,
        apiAccessibleOnCurrentPlan: false,
        startDate: "2026-02-06",
        endDate: "2026-06-07",
        status: "active",
    },
];
function findCompetitionSeasonProfileForLeague(params) {
    if (params.competitionKey === undefined && params.externalLeagueId === undefined) {
        return undefined;
    }
    return exports.competitionSeasonProfiles.find((profile) => {
        const competitionKeyMatches = params.competitionKey === undefined ||
            profile.competitionKey === params.competitionKey;
        const externalLeagueIdMatches = params.externalLeagueId === undefined ||
            profile.externalLeagueId === params.externalLeagueId;
        return competitionKeyMatches && externalLeagueIdMatches;
    });
}
//# sourceMappingURL=competitionSeasons.js.map