import { DateTime } from "luxon";

/**
 * Convert a UTC ISO string to JST storage string "YYYY-MM-DD HH:mm".
 * All external API dates arrive as UTC; this is the single conversion point.
 */
export function toJstStorageString(utcIso: string): string {
  return DateTime.fromISO(utcIso, { zone: "utc" })
    .setZone("Asia/Tokyo")
    .toFormat("yyyy-MM-dd HH:mm");
}

/**
 * Convert a UTC ISO string to a Firestore-compatible JS Date (UTC).
 */
export function toUtcDate(utcIso: string): Date {
  return DateTime.fromISO(utcIso, { zone: "utc" }).toJSDate();
}

/**
 * Format a UTC Date for iCalendar DTSTART (YYYYMMDDTHHmmssZ).
 */
export function toICalDateString(date: Date): string {
  return DateTime.fromJSDate(date, { zone: "utc" }).toFormat(
    "yyyyMMdd'T'HHmmss'Z'"
  );
}

/**
 * Map RapidAPI status short codes to our GameStatus enum.
 */
export function mapFootballStatus(
  short: string
): "scheduled" | "live" | "finished" | "postponed" | "cancelled" {
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

export function mapBaseballStatus(
  short: string
): "scheduled" | "live" | "finished" | "postponed" | "cancelled" {
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
