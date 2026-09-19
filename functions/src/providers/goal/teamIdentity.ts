const INTERNAL_TEAM_BY_GOAL_ID: Readonly<Record<string, string>> = Object.freeze({
  cmr7be2nq0qkwrx06zxbqr5ux: "kawasaki_frontale",
  cmr7foowe2kf3rx06u6eu3rhl: "arsenal",
});

export function internalTeamIdForGoalTeam(goalTeamId: string): string | undefined {
  return INTERNAL_TEAM_BY_GOAL_ID[goalTeamId];
}

export function goalTeamIdForInternalTeam(teamId: string): string | undefined {
  return Object.keys(INTERNAL_TEAM_BY_GOAL_ID).find((id) => INTERNAL_TEAM_BY_GOAL_ID[id] === teamId);
}
