"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GoogleCalendarSyncService = exports.CredentialError = void 0;
exports.syncUsersBounded = syncUsersBounded;
const connectionService_1 = require("./connectionService");
const reconciliation_1 = require("./reconciliation");
class CredentialError extends Error {
    constructor(permanent, code) {
        super(code);
        this.permanent = permanent;
        this.code = code;
    }
}
exports.CredentialError = CredentialError;
class GoogleCalendarSyncService {
    constructor(store, google, encryptionKey) {
        this.store = store;
        this.google = google;
        this.encryptionKey = encryptionKey;
    }
    async sync(uid) {
        const connection = await this.store.getConnection(uid);
        if (connection?.status !== "active" || !connection.calendarId)
            throw new connectionService_1.CalendarConnectionError("not-connected");
        try {
            const encrypted = await this.store.getCredential(uid);
            if (!encrypted)
                throw new CredentialError(true, "credential-missing");
            const refreshToken = (0, connectionService_1.decryptRefreshToken)(encrypted, this.encryptionKey);
            const accessToken = await this.google.refresh(refreshToken);
            let calendarId = connection.calendarId;
            let calendarRecreated = false;
            if (!await this.google.calendarUsable(accessToken, calendarId)) {
                calendarId = await this.google.createCalendar(accessToken);
                await this.store.updateCalendar(uid, calendarId);
                calendarRecreated = true;
            }
            const summary = await (0, reconciliation_1.reconcileEvents)(this.google.events(accessToken), calendarId, await this.store.getGames(uid));
            const result = { status: "synced", ...summary, calendarRecreated };
            await this.store.record(uid, { status: result.status, summary, calendarRecreated });
            return result;
        }
        catch (error) {
            const permanent = error instanceof CredentialError && error.permanent ||
                error instanceof connectionService_1.CalendarConnectionError && error.code === "invalid-encrypted-credential";
            const code = permanent ? "reauth-required" : error instanceof CredentialError ? error.code : "provider-error";
            if (permanent)
                await this.store.requireReauth(uid);
            await this.store.record(uid, { status: permanent ? "reauth_required" : "error", errorCode: code });
            if (permanent)
                return { status: "reauth_required", created: 0, updated: 0, deleted: 0, unchanged: 0, calendarRecreated: false };
            throw error;
        }
    }
}
exports.GoogleCalendarSyncService = GoogleCalendarSyncService;
/** Quota-safe batch runner: no more than `concurrency` users are in flight. */
async function syncUsersBounded(uids, sync, concurrency = 3) {
    let cursor = 0;
    let synced = 0;
    let failed = 0;
    const worker = async () => { while (cursor < uids.length) {
        const uid = uids[cursor++];
        try {
            await sync(uid);
            synced++;
        }
        catch (_) {
            failed++;
        }
    } };
    await Promise.all(Array.from({ length: Math.min(concurrency, uids.length) }, worker));
    return { considered: uids.length, synced, failed };
}
//# sourceMappingURL=syncService.js.map