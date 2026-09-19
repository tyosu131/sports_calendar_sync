import { GameStatus } from "../../types";

const STATUS_MAP: Readonly<Record<string, GameStatus>> = Object.freeze({
  SCHEDULED: "scheduled",
  LIVE: "live",
  HALF_TIME: "live",
  FINISHED: "finished",
  AFTER_ET: "finished",
  AFTER_PEN: "finished",
  POSTPONED: "postponed",
  CANCELLED: "cancelled",
});

const TEMPORAL_STATUSES = new Set(["LIVE", "HALF_TIME", "FINISHED", "AFTER_ET", "AFTER_PEN"]);

export function goalGameStatus(providerStatus: string): GameStatus | undefined {
  return STATUS_MAP[providerStatus];
}

export function isGoalTemporalAnomaly(
  providerStatus: string,
  kickoffUtc: string,
  now: Date,
  toleranceMs = 5 * 60 * 1000
): boolean {
  const kickoff = new Date(kickoffUtc).getTime();
  return TEMPORAL_STATUSES.has(providerStatus) && Number.isFinite(kickoff) &&
    kickoff > now.getTime() + toleranceMs;
}
