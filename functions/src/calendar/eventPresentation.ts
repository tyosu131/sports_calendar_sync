import { GameStatus } from "../types";

export interface PresentableGame {
  homeTeamName: string;
  awayTeamName: string;
  competitionCompact?: string;
  status: GameStatus;
  homeScore?: number;
  awayScore?: number;
  venue?: string | null;
}

export interface CalendarEventPresentation {
  title: string;
  venue?: string;
  status: GameStatus;
}

/** The provider-independent presentation shared by ICS and direct API adapters. */
export function presentCalendarGame(game: PresentableGame): CalendarEventPresentation {
  const scoreIsAuthoritative = game.status === "finished" &&
    Number.isInteger(game.homeScore) && Number.isInteger(game.awayScore) &&
    game.homeScore! >= 0 && game.awayScore! >= 0;
  const matchup = scoreIsAuthoritative
    ? `${game.homeTeamName} ${game.homeScore}-${game.awayScore} ${game.awayTeamName}`
    : `${game.homeTeamName} vs ${game.awayTeamName}`;
  return {
    title: `${game.competitionCompact ? `[${game.competitionCompact}] ` : ""}${matchup}`,
    ...(game.venue ? {venue: game.venue} : {}),
    status: game.status,
  };
}
