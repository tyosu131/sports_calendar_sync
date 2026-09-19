"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.goalGameStatus = goalGameStatus;
exports.isGoalTemporalAnomaly = isGoalTemporalAnomaly;
const STATUS_MAP = Object.freeze({
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
function goalGameStatus(providerStatus) {
    return STATUS_MAP[providerStatus];
}
function isGoalTemporalAnomaly(providerStatus, kickoffUtc, now, toleranceMs = 5 * 60 * 1000) {
    const kickoff = new Date(kickoffUtc).getTime();
    return TEMPORAL_STATUSES.has(providerStatus) && Number.isFinite(kickoff) &&
        kickoff > now.getTime() + toleranceMs;
}
//# sourceMappingURL=statusPolicy.js.map