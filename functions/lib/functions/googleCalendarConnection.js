"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncService = syncService;
exports.callbackHtml = callbackHtml;
exports.createGoogleCalendarHandlers = createGoogleCalendarHandlers;
exports.syncAllActiveGoogleCalendars = syncAllActiveGoogleCalendars;
const axios_1 = __importDefault(require("axios"));
const functions = __importStar(require("firebase-functions/v1"));
const firestore_1 = require("firebase-admin/firestore");
const connectionService_1 = require("../googleCalendar/connectionService");
const syncService_1 = require("../googleCalendar/syncService");
const reconciliation_1 = require("../googleCalendar/reconciliation");
const getCalendar_1 = require("./getCalendar");
const calendarFeeds_1 = require("./calendarFeeds");
class FirestoreConnectionStore {
    constructor(db) {
        this.db = db;
    }
    async createState(hash, uid, expiresAt) {
        await this.db.collection("googleCalendarOAuthStates").doc(hash).create({
            uid, expiresAt: firestore_1.Timestamp.fromDate(expiresAt), createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    async consumeState(hash, now) {
        return this.db.runTransaction(async (transaction) => {
            const ref = this.db.collection("googleCalendarOAuthStates").doc(hash);
            const snapshot = await transaction.get(ref);
            if (!snapshot.exists)
                return undefined;
            transaction.delete(ref); // Invalid and expired states are single-use too.
            const uid = snapshot.get("uid");
            const expiresAt = snapshot.get("expiresAt");
            if (typeof uid !== "string" || !(expiresAt instanceof firestore_1.Timestamp) || expiresAt.toDate() <= now) {
                return undefined;
            }
            return uid;
        });
    }
    async getConnection(uid) {
        const snapshot = await this.db.collection("googleCalendarConnections").doc(uid).get();
        return snapshot.exists ? snapshot.data() : undefined;
    }
    async saveConnection(uid, value) {
        await this.db.collection("googleCalendarConnections").doc(uid).set({
            ...value,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            ...(value.status === "active" ? { connectedAt: firestore_1.FieldValue.serverTimestamp() } : { disconnectedAt: firestore_1.FieldValue.serverTimestamp() }),
            ...(value.status === "active" ? { lastSyncStatus: "pending", lastSyncErrorCode: firestore_1.FieldValue.delete() } : {}),
        }, { merge: true });
    }
    async saveCredential(uid, value) {
        await this.db.collection("googleCalendarCredentials").doc(uid).set({
            ...value, updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    async deleteCredential(uid) {
        await this.db.collection("googleCalendarCredentials").doc(uid).delete();
    }
}
class GoogleHttpGateway {
    constructor(config) {
        this.config = config;
        this.tokens = new Map();
    }
    async access(code) {
        const body = new URLSearchParams({
            code, client_id: this.config.clientId, client_secret: this.config.clientSecret,
            redirect_uri: this.config.redirectUri, grant_type: "authorization_code",
        });
        const response = await axios_1.default.post("https://oauth2.googleapis.com/token", body.toString(), {
            headers: { "content-type": "application/x-www-form-urlencoded" },
        });
        return {
            accessToken: response.data.access_token,
            refreshToken: response.data.refresh_token,
            scopes: typeof response.data.scope === "string" ? response.data.scope.split(" ") : [],
        };
    }
    async exchangeCode(code) {
        const result = await this.access(code);
        if (result.refreshToken)
            this.tokens.set(result.refreshToken, result.accessToken);
        return { refreshToken: result.refreshToken, scopes: result.scopes };
    }
    headers(refreshToken) { return { Authorization: `Bearer ${this.tokens.get(refreshToken)}` }; }
    rethrowCredential(error) {
        if (axios_1.default.isAxiosError(error) && error.response?.status === 401) {
            throw new connectionService_1.CalendarConnectionError("revoked-or-invalid-credential");
        }
        throw error;
    }
    async isCalendarAccessible(refreshToken, calendarId) {
        try {
            await axios_1.default.get(`https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}`, { headers: this.headers(refreshToken) });
            return true;
        }
        catch (error) {
            if (axios_1.default.isAxiosError(error) && [404, 410].includes(error.response?.status ?? 0)) {
                return false;
            }
            return this.rethrowCredential(error);
        }
    }
    async createCalendar(refreshToken) {
        try {
            const response = await axios_1.default.post("https://www.googleapis.com/calendar/v3/calendars", {
                summary: connectionService_1.CALENDAR_NAME, description: connectionService_1.CALENDAR_MARKER, timeZone: "Asia/Tokyo",
            }, { headers: this.headers(refreshToken) });
            if (typeof response.data.id !== "string")
                throw new Error("Calendar id missing");
            return response.data.id;
        }
        catch (error) {
            return this.rethrowCredential(error);
        }
    }
}
class FirestoreSyncStore {
    constructor(db) {
        this.db = db;
    }
    async getConnection(uid) { return new FirestoreConnectionStore(this.db).getConnection(uid); }
    async getCredential(uid) {
        const doc = await this.db.collection("googleCalendarCredentials").doc(uid).get();
        return doc.exists ? doc.data() : undefined;
    }
    async getGames(uid) {
        const repository = new getCalendar_1.FirestorePersonalizedCalendarRepository(this.db);
        const user = await repository.findUser(uid);
        if (!user?.followedTeamIds.length)
            return [];
        const allowed = new Set(user.followedTeamIds);
        return (await repository.findCalendarGamesForTeams(user.followedTeamIds)).filter(game => game.homeTeamId !== undefined && allowed.has(game.homeTeamId) ||
            game.awayTeamId !== undefined && allowed.has(game.awayTeamId));
    }
    async updateCalendar(uid, calendarId) {
        await this.db.collection("googleCalendarConnections").doc(uid).set({ calendarId, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    }
    async record(uid, value) {
        await this.db.collection("googleCalendarConnections").doc(uid).set({
            lastSyncAt: firestore_1.FieldValue.serverTimestamp(), lastSyncStatus: value.status,
            lastSyncErrorCode: value.errorCode ?? firestore_1.FieldValue.delete(),
            lastSyncSummary: value.summary ?? firestore_1.FieldValue.delete(), calendarRecreated: value.calendarRecreated ?? false,
        }, { merge: true });
    }
    async requireReauth(uid) {
        const batch = this.db.batch();
        batch.set(this.db.collection("googleCalendarConnections").doc(uid), { status: "reauth_required", updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
        batch.delete(this.db.collection("googleCalendarCredentials").doc(uid));
        await batch.commit();
    }
}
class GoogleSyncHttpGateway {
    constructor(config) {
        this.config = config;
    }
    async refresh(refreshToken) {
        try {
            const body = new URLSearchParams({ refresh_token: refreshToken, client_id: this.config.clientId,
                client_secret: this.config.clientSecret, grant_type: "refresh_token" });
            const response = await axios_1.default.post("https://oauth2.googleapis.com/token", body.toString(), { headers: { "content-type": "application/x-www-form-urlencoded" } });
            if (typeof response.data.access_token !== "string")
                throw new Error("access-token-missing");
            return response.data.access_token;
        }
        catch (error) {
            const permanent = axios_1.default.isAxiosError(error) && error.response?.data?.error === "invalid_grant";
            throw new syncService_1.CredentialError(permanent, permanent ? "invalid-grant" : "token-refresh-failed");
        }
    }
    headers(token) { return { Authorization: `Bearer ${token}` }; }
    async calendarUsable(token, id) {
        try {
            await axios_1.default.get(`https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(id)}`, { headers: this.headers(token) });
            return true;
        }
        catch (error) {
            if (axios_1.default.isAxiosError(error) && [404, 410].includes(error.response?.status ?? 0))
                return false;
            if (axios_1.default.isAxiosError(error) && [401, 403].includes(error.response?.status ?? 0))
                throw new syncService_1.CredentialError(true, "credential-rejected");
            throw error;
        }
    }
    async createCalendar(token) {
        const response = await axios_1.default.post("https://www.googleapis.com/calendar/v3/calendars", { summary: connectionService_1.CALENDAR_NAME, description: connectionService_1.CALENDAR_MARKER, timeZone: "Asia/Tokyo" }, { headers: this.headers(token) });
        if (typeof response.data.id !== "string")
            throw new Error("calendar-id-missing");
        return response.data.id;
    }
    events(token) {
        const base = (calendarId) => `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events`;
        return {
            listManaged: async (calendarId) => {
                const events = [];
                let pageToken;
                do {
                    const response = await axios_1.default.get(base(calendarId), { headers: this.headers(token), params: {
                            privateExtendedProperty: `sportsCalendarSync=${reconciliation_1.MANAGED_EVENT_MARKER}`, showDeleted: false, maxResults: 2500, pageToken,
                        } });
                    events.push(...(Array.isArray(response.data.items) ? response.data.items : []));
                    pageToken = response.data.nextPageToken;
                } while (pageToken);
                return events;
            },
            insert: async (calendarId, event) => {
                try {
                    await axios_1.default.post(base(calendarId), event, { headers: this.headers(token) });
                }
                catch (error) {
                    // A manually deleted deterministic ID can remain as a Google tombstone.
                    // Replacing that same ID restores it without creating a duplicate.
                    if (axios_1.default.isAxiosError(error) && error.response?.status === 409) {
                        await axios_1.default.put(`${base(calendarId)}/${encodeURIComponent(event.id)}`, event, { headers: this.headers(token) });
                    }
                    else
                        throw error;
                }
            },
            update: async (calendarId, id, event) => { await axios_1.default.put(`${base(calendarId)}/${encodeURIComponent(id)}`, event, { headers: this.headers(token) }); },
            remove: async (calendarId, id) => { await axios_1.default.delete(`${base(calendarId)}/${encodeURIComponent(id)}`, { headers: this.headers(token) }); },
        };
    }
}
function service(secrets) {
    return new connectionService_1.GoogleCalendarConnectionService(new FirestoreConnectionStore((0, firestore_1.getFirestore)()), new GoogleHttpGateway(secrets), { clientId: secrets.clientId, redirectUri: secrets.redirectUri, encryptionKey: secrets.encryptionKey });
}
function syncService(secrets) {
    const db = (0, firestore_1.getFirestore)();
    return new syncService_1.GoogleCalendarSyncService(new FirestoreSyncStore(db), new GoogleSyncHttpGateway(secrets), secrets.encryptionKey);
}
const APP_RETURN_URL = "sportscalendar://google-calendar/oauth-complete";
function callbackHtml(success) {
    const title = success ? "Google Calendarとの連携が完了しました" : "Google Calendarとの連携を完了できませんでした";
    const detail = success ? "アプリに戻ると同期を開始します。" : "アプリに戻って、もう一度お試しください。";
    return `<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${title}</title><style>body{font-family:system-ui;margin:0;background:#f5f7fa;color:#182230}.card{max-width:34rem;margin:12vh auto;padding:2rem;background:white;border-radius:16px;box-shadow:0 4px 24px #0002}a{display:inline-block;margin-top:1rem;padding:.8rem 1.2rem;background:#1769aa;color:white;border-radius:9px;text-decoration:none}</style></head><body><main class="card"><h1>${title}</h1><p>${detail}</p><a href="${APP_RETURN_URL}">Sports Calendarに戻る</a><p><small>自動的に開かない場合は上のボタンを押してください。</small></p></main>${success ? `<script>setTimeout(function(){location.href=${JSON.stringify(APP_RETURN_URL)}},300)</script>` : ""}</body></html>`;
}
function callableError(error) {
    const code = error instanceof connectionService_1.CalendarConnectionError ? error.code : "internal-error";
    const precondition = ["invalid-encryption-key"].includes(code);
    throw new functions.https.HttpsError(precondition ? "failed-precondition" : "internal", code);
}
function createGoogleCalendarHandlers(secrets) {
    return {
        begin: async (_data, context) => {
            const uid = (0, calendarFeeds_1.requireAuthenticatedUid)(context);
            try {
                return { authorizationUrl: await service(secrets).begin(uid) };
            }
            catch (error) {
                return callableError(error);
            }
        },
        status: async (_data, context) => {
            const uid = (0, calendarFeeds_1.requireAuthenticatedUid)(context);
            const base = await service(secrets).status(uid);
            const connection = await new FirestoreConnectionStore((0, firestore_1.getFirestore)()).getConnection(uid);
            return { ...base, ...(connection?.lastSyncStatus ? { syncStatus: connection.lastSyncStatus } : {}) };
        },
        disconnect: async (_data, context) => {
            const uid = (0, calendarFeeds_1.requireAuthenticatedUid)(context);
            await service(secrets).disconnect(uid);
            return { connected: false };
        },
        callback: async (request, response) => {
            const query = request.query;
            try {
                await service(secrets).callback(query);
                response.status(200).type("html").send(callbackHtml(true));
            }
            catch (error) {
                const code = error instanceof connectionService_1.CalendarConnectionError ? error.code : "connection-failed";
                const status = ["malformed-callback", "invalid-or-expired-state", "oauth-denied"].includes(code) ? 400 : 502;
                console.warn("Google Calendar OAuth callback failed", { code });
                response.status(status).type("html").send(callbackHtml(false));
            }
        },
        sync: async (_data, context) => {
            const uid = (0, calendarFeeds_1.requireAuthenticatedUid)(context);
            try {
                return await syncService(secrets).sync(uid);
            }
            catch (_) {
                throw new functions.https.HttpsError("unavailable", "google-calendar-sync-failed");
            }
        },
    };
}
async function syncAllActiveGoogleCalendars(secrets) {
    const snapshot = await (0, firestore_1.getFirestore)().collection("googleCalendarConnections").where("status", "==", "active").get();
    const result = await (0, syncService_1.syncUsersBounded)(snapshot.docs.map(doc => doc.id), uid => syncService(secrets).sync(uid));
    console.info("Google Calendar batch reconciliation complete", result);
    return result;
}
//# sourceMappingURL=googleCalendarConnection.js.map