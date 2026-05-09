import { CompetitionKey } from "../types";

export type CompetitionSeasonStatus = "active" | "upcoming" | "archived";

export interface CompetitionSeasonProfile {
  competitionKey: CompetitionKey;
  competitionSeasonKey: string;
  displayNameJa: string;
  displayNameEn: string;
  externalLeagueId: number;
  apiSeason: number;
  apiAccessibleOnCurrentPlan: boolean;
  startDate: string;
  endDate: string;
  status: CompetitionSeasonStatus;
}

export const CURRENT_J1_COMPETITION_SEASON_KEY =
  "football_j1_2026_hyakunen";

export const competitionSeasonProfiles: CompetitionSeasonProfile[] = [
  {
    competitionKey: "football_j1",
    competitionSeasonKey: CURRENT_J1_COMPETITION_SEASON_KEY,
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

export function findCompetitionSeasonProfileForLeague(params: {
  competitionKey?: string;
  externalLeagueId?: number;
}): CompetitionSeasonProfile | undefined {
  if (params.competitionKey === undefined && params.externalLeagueId === undefined) {
    return undefined;
  }

  return competitionSeasonProfiles.find((profile) => {
    const competitionKeyMatches =
      params.competitionKey === undefined ||
      profile.competitionKey === params.competitionKey;
    const externalLeagueIdMatches =
      params.externalLeagueId === undefined ||
      profile.externalLeagueId === params.externalLeagueId;
    return competitionKeyMatches && externalLeagueIdMatches;
  });
}
