"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calendarEventUid = calendarEventUid;
exports.buildCalendar = buildCalendar;
const CRLF = "\r\n";
function text(value) {
    return value
        .replace(/\\/g, "\\\\")
        .replace(/\r\n|\r|\n/g, "\\n")
        .replace(/,/g, "\\,")
        .replace(/;/g, "\\;");
}
function utc(date) {
    if (Number.isNaN(date.getTime()))
        throw new Error("Invalid kickoffUtc");
    return date.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}Z$/, "Z");
}
/** Builds a stable UID from domain identity only, never from mutable game data. */
function calendarEventUid(gameId) {
    if (!gameId)
        throw new Error("Game id is required");
    return `${gameId}@sports-calendar-sync`;
}
/** Pure, provider-independent and byte-for-byte deterministic iCalendar output. */
function buildCalendar(games) {
    const unique = new Map();
    for (const game of games) {
        if (!unique.has(game.id))
            unique.set(game.id, game);
    }
    const events = [...unique.values()].sort((a, b) => a.id.localeCompare(b.id));
    const lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//sports-calendar-sync//Calendar V1//EN",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "X-WR-CALNAME:Sports Calendar",
    ];
    for (const game of events) {
        const allowed = [
            "scheduled", "live", "finished", "postponed", "cancelled",
        ];
        if (!allowed.includes(game.status))
            throw new Error(`Unknown game status: ${game.status}`);
        lines.push("BEGIN:VEVENT");
        lines.push(`UID:${text(calendarEventUid(game.id))}`);
        // DTSTAMP is required by RFC 5545. A constant value avoids introducing a
        // clock dependency; freshness is represented by each game's DTSTART.
        lines.push("DTSTAMP:19700101T000000Z");
        lines.push(`DTSTART:${utc(game.kickoffUtc)}`);
        lines.push(`SUMMARY:${text(`${game.homeTeamName} vs ${game.awayTeamName}`)}`);
        if (game.venue)
            lines.push(`LOCATION:${text(game.venue)}`);
        const platforms = game.broadcastPlatforms?.map((item) => item.platform).filter(Boolean);
        if (platforms?.length)
            lines.push(`DESCRIPTION:${text(`Viewing: ${platforms.join(" / ")}`)}`);
        if (game.status === "cancelled")
            lines.push("STATUS:CANCELLED");
        // RFC 5545 has no POSTPONED status. TENTATIVE preserves the UID while
        // communicating that the published kickoff is not confirmed.
        if (game.status === "postponed")
            lines.push("STATUS:TENTATIVE");
        lines.push("END:VEVENT");
    }
    lines.push("END:VCALENDAR", "");
    return lines.join(CRLF);
}
//# sourceMappingURL=icsBuilder.js.map