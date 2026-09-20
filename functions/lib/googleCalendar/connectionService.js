"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.GoogleCalendarConnectionService = exports.CalendarConnectionError = exports.CALENDAR_MARKER = exports.CALENDAR_NAME = exports.GOOGLE_CALENDAR_SCOPE = void 0;
exports.encryptRefreshToken = encryptRefreshToken;
const crypto_1 = require("crypto");
exports.GOOGLE_CALENDAR_SCOPE = "https://www.googleapis.com/auth/calendar.app.created";
exports.CALENDAR_NAME = "Sports Calendar";
exports.CALENDAR_MARKER = "sports-calendar-sync:app-created";
class CalendarConnectionError extends Error {
    constructor(code) {
        super(code);
        this.code = code;
    }
}
exports.CalendarConnectionError = CalendarConnectionError;
function encryptRefreshToken(token, base64Key) {
    const key = Buffer.from(base64Key, "base64");
    if (key.length !== 32)
        throw new CalendarConnectionError("invalid-encryption-key");
    const iv = (0, crypto_1.randomBytes)(12);
    const cipher = (0, crypto_1.createCipheriv)("aes-256-gcm", key, iv);
    const ciphertext = Buffer.concat([cipher.update(token, "utf8"), cipher.final()]);
    return {
        algorithm: "aes-256-gcm",
        ciphertext: ciphertext.toString("base64"),
        iv: iv.toString("base64"),
        authTag: cipher.getAuthTag().toString("base64"),
    };
}
class GoogleCalendarConnectionService {
    constructor(store, google, config, now = () => new Date(), random = () => (0, crypto_1.randomBytes)(32).toString("base64url")) {
        this.store = store;
        this.google = google;
        this.config = config;
        this.now = now;
        this.random = random;
    }
    async begin(uid) {
        const state = this.random();
        const expiresAt = new Date(this.now().getTime() + 10 * 60 * 1000);
        await this.store.createState(hashState(state), uid, expiresAt);
        const query = new URLSearchParams({
            client_id: this.config.clientId,
            redirect_uri: this.config.redirectUri,
            response_type: "code",
            scope: exports.GOOGLE_CALENDAR_SCOPE,
            access_type: "offline",
            include_granted_scopes: "true",
            prompt: "consent",
            state,
        });
        return `https://accounts.google.com/o/oauth2/v2/auth?${query}`;
    }
    async callback(input) {
        if (!input.state)
            throw new CalendarConnectionError("malformed-callback");
        const uid = await this.store.consumeState(hashState(input.state), this.now());
        if (!uid)
            throw new CalendarConnectionError("invalid-or-expired-state");
        if (input.error)
            throw new CalendarConnectionError("oauth-denied");
        if (!input.code)
            throw new CalendarConnectionError("malformed-callback");
        let token;
        try {
            token = await this.google.exchangeCode(input.code);
        }
        catch (_) {
            throw new CalendarConnectionError("token-exchange-failed");
        }
        if (!token.refreshToken)
            throw new CalendarConnectionError("missing-refresh-token");
        // Validate local credential configuration before making an irreversible
        // external change. In particular, a bad encryption key must never leave an
        // unrecorded Google calendar behind.
        const encryptedCredential = encryptRefreshToken(token.refreshToken, this.config.encryptionKey);
        const previous = await this.store.getConnection(uid);
        let calendarId = previous?.calendarId;
        try {
            calendarId = calendarId ?? await this.google.createCalendar(token.refreshToken);
        }
        catch (error) {
            if (error instanceof CalendarConnectionError)
                throw error;
            throw new CalendarConnectionError("calendar-creation-failed");
        }
        await this.store.saveCredential(uid, encryptedCredential);
        await this.store.saveConnection(uid, {
            status: "active", calendarId, grantedScopes: token.scopes,
        });
    }
    async status(uid) {
        const connection = await this.store.getConnection(uid);
        return connection?.status === "active"
            ? { connected: true, calendarName: exports.CALENDAR_NAME }
            : { connected: false };
    }
    async disconnect(uid) {
        const existing = await this.store.getConnection(uid);
        await this.store.deleteCredential(uid);
        await this.store.saveConnection(uid, { ...existing, status: "disconnected" });
    }
}
exports.GoogleCalendarConnectionService = GoogleCalendarConnectionService;
const crypto_2 = require("crypto");
function hashState(value) {
    return (0, crypto_2.createHash)("sha256").update(value).digest("hex");
}
//# sourceMappingURL=connectionService.js.map