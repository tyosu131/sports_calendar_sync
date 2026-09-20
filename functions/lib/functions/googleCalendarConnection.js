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
exports.createGoogleCalendarHandlers = createGoogleCalendarHandlers;
const axios_1 = __importDefault(require("axios"));
const functions = __importStar(require("firebase-functions/v1"));
const firestore_1 = require("firebase-admin/firestore");
const connectionService_1 = require("../googleCalendar/connectionService");
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
function service(secrets) {
    return new connectionService_1.GoogleCalendarConnectionService(new FirestoreConnectionStore((0, firestore_1.getFirestore)()), new GoogleHttpGateway(secrets), { clientId: secrets.clientId, redirectUri: secrets.redirectUri, encryptionKey: secrets.encryptionKey });
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
            return service(secrets).status(uid);
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
                response.status(200).type("html").send("Google Calendar connection completed. You may return to Sports Calendar.");
            }
            catch (error) {
                const code = error instanceof connectionService_1.CalendarConnectionError ? error.code : "connection-failed";
                const status = ["malformed-callback", "invalid-or-expired-state", "oauth-denied"].includes(code) ? 400 : 502;
                response.status(status).type("text").send(code);
            }
        },
    };
}
//# sourceMappingURL=googleCalendarConnection.js.map