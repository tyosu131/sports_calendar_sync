"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toJstStorageString = toJstStorageString;
exports.toUtcDate = toUtcDate;
exports.toICalDateString = toICalDateString;
exports.mapFootballStatus = mapFootballStatus;
exports.mapBaseballStatus = mapBaseballStatus;
const luxon_1 = require("luxon");
/**
 * Convert a UTC ISO string to JST storage string "YYYY-MM-DD HH:mm".
 * All external API dates arrive as UTC; this is the single conversion point.
 */
function toJstStorageString(utcIso) {
    return luxon_1.DateTime.fromISO(utcIso, { zone: "utc" })
        .setZone("Asia/Tokyo")
        .toFormat("yyyy-MM-dd HH:mm");
}
/**
 * Convert a UTC ISO string to a Firestore-compatible JS Date (UTC).
 */
function toUtcDate(utcIso) {
    return luxon_1.DateTime.fromISO(utcIso, { zone: "utc" }).toJSDate();
}
/**
 * Format a UTC Date for iCalendar DTSTART (YYYYMMDDTHHmmssZ).
 */
function toICalDateString(date) {
    return luxon_1.DateTime.fromJSDate(date, { zone: "utc" }).toFormat("yyyyMMdd'T'HHmmss'Z'");
}
/**
 * Map RapidAPI status short codes to our GameStatus enum.
 */
function mapFootballStatus(short) {
    switch (short) {
        case "NS":
        case "TBD":
            return "scheduled";
        case "1H":
        case "HT":
        case "2H":
        case "ET":
        case "BT":
        case "P":
        case "SUSP":
        case "INT":
        case "LIVE":
            return "live";
        case "FT":
        case "AET":
        case "PEN":
            return "finished";
        case "PST":
            return "postponed";
        case "CANC":
        case "ABD":
        case "AWD":
        case "WO":
            return "cancelled";
        default:
            return "scheduled";
    }
}
function mapBaseballStatus(short) {
    switch (short) {
        case "NS":
        case "TBD":
            return "scheduled";
        case "LIVE":
        case "IN":
            return "live";
        case "FT":
        case "AOT":
            return "finished";
        case "POST":
        case "SUSP":
            return "postponed";
        case "CANC":
            return "cancelled";
        default:
            return "scheduled";
    }
}
//# sourceMappingURL=timezone.js.map