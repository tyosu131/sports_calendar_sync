const INTERNAL_TEAM_BY_GOAL_ID: Readonly<Record<string, string>> = Object.freeze({
  cmr7be2nq0qkwrx06zxbqr5ux: "kawasaki_frontale",
  cmr7foowe2kf3rx06u6eu3rhl: "arsenal",
});

/** V1 product display names for the canonical teams this provider may map. */
const TEAM_NAME_JA_BY_INTERNAL_ID: Readonly<Record<string, string>> = Object.freeze({
  kawasaki_frontale: "川崎フロンターレ",
  arsenal: "アーセナル",
});

export function internalTeamIdForGoalTeam(goalTeamId: string): string | undefined {
  return INTERNAL_TEAM_BY_GOAL_ID[goalTeamId];
}

export function goalTeamIdForInternalTeam(teamId: string): string | undefined {
  return Object.keys(INTERNAL_TEAM_BY_GOAL_ID).find((id) => INTERNAL_TEAM_BY_GOAL_ID[id] === teamId);
}

/** Fails closed rather than exposing an internal identifier as a display name. */
export function v1TeamNameJa(teamId: string): string {
  const name = TEAM_NAME_JA_BY_INTERNAL_ID[teamId];
  if (!name) throw new Error(`Missing V1 Japanese display name for canonical team: ${teamId}`);
  return name;
}
