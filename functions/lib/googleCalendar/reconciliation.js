"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SYNTHETIC_EVENT_DURATION_MS = exports.MANAGED_EVENT_MARKER = void 0;
exports.googleEventId = googleEventId;
exports.googleEventFor = googleEventFor;
exports.reconcileEvents = reconcileEvents;
const crypto_1 = require("crypto");
const eventPresentation_1 = require("../calendar/eventPresentation");
exports.MANAGED_EVENT_MARKER = "1";
exports.SYNTHETIC_EVENT_DURATION_MS = 2 * 60 * 60 * 1000;
/** Google permits base32hex event IDs; a prefixed SHA-256 hex digest is stable and valid. */
function googleEventId(gameId) {
    if (!gameId)
        throw new Error("Game id is required");
    return `sc${(0, crypto_1.createHash)("sha256").update(gameId).digest("hex")}`;
}
function googleEventFor(game) {
    const view = (0, eventPresentation_1.presentCalendarGame)(game);
    return {
        id: googleEventId(game.id), summary: view.title,
        ...(view.venue ? { location: view.venue } : {}),
        status: view.status === "cancelled" ? "cancelled" : view.status === "postponed" ? "tentative" : "confirmed",
        start: { dateTime: game.kickoffUtc.toISOString() },
        // Google requires an end. It is adapter-only synthetic data, never canonical provider truth.
        end: { dateTime: new Date(game.kickoffUtc.getTime() + exports.SYNTHETIC_EVENT_DURATION_MS).toISOString() },
        extendedProperties: { private: { sportsCalendarSync: exports.MANAGED_EVENT_MARKER, gameId: game.id } },
    };
}
function signature(event) {
    return JSON.stringify({ summary: event.summary, location: event.location ?? null, status: event.status,
        start: event.start, end: event.end, extendedProperties: event.extendedProperties });
}
async function reconcileEvents(gateway, calendarId, games) {
    const desired = new Map(games.map(game => { const event = googleEventFor(game); return [event.id, event]; }));
    const existing = new Map((await gateway.listManaged(calendarId))
        .filter(event => event.extendedProperties?.private?.sportsCalendarSync === exports.MANAGED_EVENT_MARKER)
        .map(event => [event.id, event]));
    const result = { created: 0, updated: 0, deleted: 0, unchanged: 0 };
    for (const [id, event] of desired) {
        const current = existing.get(id);
        if (!current) {
            await gateway.insert(calendarId, event);
            result.created++;
        }
        else if (signature(current) !== signature(event)) {
            await gateway.update(calendarId, id, event);
            result.updated++;
        }
        else
            result.unchanged++;
        existing.delete(id);
    }
    for (const id of existing.keys()) {
        await gateway.remove(calendarId, id);
        result.deleted++;
    }
    return result;
}
//# sourceMappingURL=reconciliation.js.map