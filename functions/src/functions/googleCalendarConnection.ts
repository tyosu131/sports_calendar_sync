import axios from "axios";
import * as functions from "firebase-functions/v1";
import { FieldValue, Firestore, Timestamp, getFirestore } from "firebase-admin/firestore";
import {
  CALENDAR_MARKER,
  CALENDAR_NAME,
  CalendarConnectionError,
  Connection,
  ConnectionStore,
  EncryptedCredential,
  GoogleCalendarConnectionService,
  GoogleGateway,
} from "../googleCalendar/connectionService";
import { requireAuthenticatedUid } from "./calendarFeeds";

export type GoogleCalendarSecrets = {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  encryptionKey: string;
};

class FirestoreConnectionStore implements ConnectionStore {
  constructor(private readonly db: Firestore) {}

  async createState(hash: string, uid: string, expiresAt: Date): Promise<void> {
    await this.db.collection("googleCalendarOAuthStates").doc(hash).create({
      uid, expiresAt: Timestamp.fromDate(expiresAt), createdAt: FieldValue.serverTimestamp(),
    });
  }

  async consumeState(hash: string, now: Date): Promise<string | undefined> {
    return this.db.runTransaction(async transaction => {
      const ref = this.db.collection("googleCalendarOAuthStates").doc(hash);
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) return undefined;
      transaction.delete(ref); // Invalid and expired states are single-use too.
      const uid = snapshot.get("uid");
      const expiresAt = snapshot.get("expiresAt");
      if (typeof uid !== "string" || !(expiresAt instanceof Timestamp) || expiresAt.toDate() <= now) {
        return undefined;
      }
      return uid;
    });
  }

  async getConnection(uid: string): Promise<Connection | undefined> {
    const snapshot = await this.db.collection("googleCalendarConnections").doc(uid).get();
    return snapshot.exists ? snapshot.data() as Connection : undefined;
  }

  async saveConnection(uid: string, value: Connection): Promise<void> {
    await this.db.collection("googleCalendarConnections").doc(uid).set({
      ...value,
      updatedAt: FieldValue.serverTimestamp(),
      ...(value.status === "active" ? {connectedAt: FieldValue.serverTimestamp()} : {disconnectedAt: FieldValue.serverTimestamp()}),
    }, {merge: true});
  }

  async saveCredential(uid: string, value: EncryptedCredential): Promise<void> {
    await this.db.collection("googleCalendarCredentials").doc(uid).set({
      ...value, updatedAt: FieldValue.serverTimestamp(),
    });
  }

  async deleteCredential(uid: string): Promise<void> {
    await this.db.collection("googleCalendarCredentials").doc(uid).delete();
  }
}

class GoogleHttpGateway implements GoogleGateway {
  constructor(private readonly config: GoogleCalendarSecrets) {}

  private async access(code: string): Promise<{accessToken: string; refreshToken?: string; scopes: string[]}> {
    const body = new URLSearchParams({
      code, client_id: this.config.clientId, client_secret: this.config.clientSecret,
      redirect_uri: this.config.redirectUri, grant_type: "authorization_code",
    });
    const response = await axios.post("https://oauth2.googleapis.com/token", body.toString(), {
      headers: {"content-type": "application/x-www-form-urlencoded"},
    });
    return {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      scopes: typeof response.data.scope === "string" ? response.data.scope.split(" ") : [],
    };
  }

  private tokens = new Map<string, string>();
  async exchangeCode(code: string): Promise<{refreshToken?: string; scopes: string[]}> {
    const result = await this.access(code);
    if (result.refreshToken) this.tokens.set(result.refreshToken, result.accessToken);
    return {refreshToken: result.refreshToken, scopes: result.scopes};
  }

  private headers(refreshToken: string) { return {Authorization: `Bearer ${this.tokens.get(refreshToken)}`}; }

  private rethrowCredential(error: unknown): never {
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      throw new CalendarConnectionError("revoked-or-invalid-credential");
    }
    throw error;
  }

  async isCalendarAccessible(refreshToken: string, calendarId: string): Promise<boolean> {
    try {
      await axios.get(
        `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}`,
        {headers: this.headers(refreshToken)}
      );
      return true;
    } catch (error) {
      if (axios.isAxiosError(error) && [404, 410].includes(error.response?.status ?? 0)) {
        return false;
      }
      return this.rethrowCredential(error);
    }
  }

  async createCalendar(refreshToken: string): Promise<string> {
    try {
      const response = await axios.post("https://www.googleapis.com/calendar/v3/calendars", {
        summary: CALENDAR_NAME, description: CALENDAR_MARKER, timeZone: "Asia/Tokyo",
      }, {headers: this.headers(refreshToken)});
      if (typeof response.data.id !== "string") throw new Error("Calendar id missing");
      return response.data.id;
    } catch (error) { return this.rethrowCredential(error); }
  }
}

function service(secrets: GoogleCalendarSecrets): GoogleCalendarConnectionService {
  return new GoogleCalendarConnectionService(
    new FirestoreConnectionStore(getFirestore()), new GoogleHttpGateway(secrets),
    {clientId: secrets.clientId, redirectUri: secrets.redirectUri, encryptionKey: secrets.encryptionKey}
  );
}

function callableError(error: unknown): never {
  const code = error instanceof CalendarConnectionError ? error.code : "internal-error";
  const precondition = ["invalid-encryption-key"].includes(code);
  throw new functions.https.HttpsError(precondition ? "failed-precondition" : "internal", code);
}

export function createGoogleCalendarHandlers(secrets: GoogleCalendarSecrets) {
  return {
    begin: async (_data: unknown, context: functions.https.CallableContext) => {
      const uid = requireAuthenticatedUid(context);
      try { return {authorizationUrl: await service(secrets).begin(uid)}; } catch (error) { return callableError(error); }
    },
    status: async (_data: unknown, context: functions.https.CallableContext) => {
      const uid = requireAuthenticatedUid(context);
      return service(secrets).status(uid);
    },
    disconnect: async (_data: unknown, context: functions.https.CallableContext) => {
      const uid = requireAuthenticatedUid(context);
      await service(secrets).disconnect(uid);
      return {connected: false};
    },
    callback: async (request: functions.https.Request, response: functions.Response) => {
      const query = request.query as {state?: string; code?: string; error?: string};
      try {
        await service(secrets).callback(query);
        response.status(200).type("html").send("Google Calendar connection completed. You may return to Sports Calendar.");
      } catch (error) {
        const code = error instanceof CalendarConnectionError ? error.code : "connection-failed";
        const status = ["malformed-callback", "invalid-or-expired-state", "oauth-denied"].includes(code) ? 400 : 502;
        response.status(status).type("text").send(code);
      }
    },
  };
}
