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
import { GoogleCalendarSyncService, SyncGoogleGateway, SyncStore, CredentialError, syncUsersBounded } from "../googleCalendar/syncService";
import { GoogleEvent, MANAGED_EVENT_MARKER, ReconcileGateway } from "../googleCalendar/reconciliation";
import { FirestorePersonalizedCalendarRepository } from "./getCalendar";
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
      ...(value.status === "active" ? {lastSyncStatus: "pending", lastSyncErrorCode: FieldValue.delete()} : {}),
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

class FirestoreSyncStore implements SyncStore {
  constructor(private db: Firestore) {}
  async getConnection(uid: string) { return new FirestoreConnectionStore(this.db).getConnection(uid); }
  async getCredential(uid: string) {
    const doc = await this.db.collection("googleCalendarCredentials").doc(uid).get();
    return doc.exists ? doc.data() as EncryptedCredential : undefined;
  }
  async getGames(uid: string) {
    const repository = new FirestorePersonalizedCalendarRepository(this.db);
    const user = await repository.findUser(uid);
    if (!user?.followedTeamIds.length) return [];
    const allowed = new Set(user.followedTeamIds);
    return (await repository.findCalendarGamesForTeams(user.followedTeamIds)).filter(game =>
      game.homeTeamId !== undefined && allowed.has(game.homeTeamId) ||
      game.awayTeamId !== undefined && allowed.has(game.awayTeamId));
  }
  async updateCalendar(uid: string, calendarId: string) {
    await this.db.collection("googleCalendarConnections").doc(uid).set({calendarId, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  }
  async record(uid: string, value: {status: string; errorCode?: string; summary?: unknown; calendarRecreated?: boolean}) {
    await this.db.collection("googleCalendarConnections").doc(uid).set({
      lastSyncAt: FieldValue.serverTimestamp(), lastSyncStatus: value.status,
      lastSyncErrorCode: value.errorCode ?? FieldValue.delete(),
      lastSyncSummary: value.summary ?? FieldValue.delete(), calendarRecreated: value.calendarRecreated ?? false,
    }, {merge: true});
  }
  async requireReauth(uid: string) {
    const batch = this.db.batch();
    batch.set(this.db.collection("googleCalendarConnections").doc(uid), {status: "reauth_required", updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    batch.delete(this.db.collection("googleCalendarCredentials").doc(uid));
    await batch.commit();
  }
}

class GoogleSyncHttpGateway implements SyncGoogleGateway {
  constructor(private config: GoogleCalendarSecrets) {}
  async refresh(refreshToken: string): Promise<string> {
    try {
      const body = new URLSearchParams({refresh_token: refreshToken, client_id: this.config.clientId,
        client_secret: this.config.clientSecret, grant_type: "refresh_token"});
      const response = await axios.post("https://oauth2.googleapis.com/token", body.toString(),
        {headers: {"content-type": "application/x-www-form-urlencoded"}});
      if (typeof response.data.access_token !== "string") throw new Error("access-token-missing");
      return response.data.access_token;
    } catch (error) {
      const permanent = axios.isAxiosError(error) && error.response?.data?.error === "invalid_grant";
      throw new CredentialError(permanent, permanent ? "invalid-grant" : "token-refresh-failed");
    }
  }
  private headers(token: string) { return {Authorization: `Bearer ${token}`}; }
  async calendarUsable(token: string, id: string) {
    try { await axios.get(`https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(id)}`, {headers: this.headers(token)}); return true; }
    catch (error) {
      if (axios.isAxiosError(error) && [404, 410].includes(error.response?.status ?? 0)) return false;
      if (axios.isAxiosError(error) && [401, 403].includes(error.response?.status ?? 0)) throw new CredentialError(true, "credential-rejected");
      throw error;
    }
  }
  async createCalendar(token: string) {
    const response = await axios.post("https://www.googleapis.com/calendar/v3/calendars",
      {summary: CALENDAR_NAME, description: CALENDAR_MARKER, timeZone: "Asia/Tokyo"}, {headers: this.headers(token)});
    if (typeof response.data.id !== "string") throw new Error("calendar-id-missing");
    return response.data.id;
  }
  events(token: string): ReconcileGateway {
    const base = (calendarId: string) => `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(calendarId)}/events`;
    return {
      listManaged: async calendarId => {
        const events: GoogleEvent[] = []; let pageToken: string | undefined;
        do {
          const response = await axios.get(base(calendarId), {headers: this.headers(token), params: {
            privateExtendedProperty: `sportsCalendarSync=${MANAGED_EVENT_MARKER}`, showDeleted: false, maxResults: 2500, pageToken,
          }});
          events.push(...(Array.isArray(response.data.items) ? response.data.items : []));
          pageToken = response.data.nextPageToken;
        } while (pageToken);
        return events;
      },
      insert: async (calendarId, event) => {
        try { await axios.post(base(calendarId), event, {headers: this.headers(token)}); }
        catch (error) {
          // A manually deleted deterministic ID can remain as a Google tombstone.
          // Replacing that same ID restores it without creating a duplicate.
          if (axios.isAxiosError(error) && error.response?.status === 409) {
            await axios.put(`${base(calendarId)}/${encodeURIComponent(event.id)}`, event, {headers: this.headers(token)});
          } else throw error;
        }
      },
      update: async (calendarId, id, event) => { await axios.put(`${base(calendarId)}/${encodeURIComponent(id)}`, event, {headers: this.headers(token)}); },
      remove: async (calendarId, id) => { await axios.delete(`${base(calendarId)}/${encodeURIComponent(id)}`, {headers: this.headers(token)}); },
    };
  }
}

function service(secrets: GoogleCalendarSecrets): GoogleCalendarConnectionService {
  return new GoogleCalendarConnectionService(
    new FirestoreConnectionStore(getFirestore()), new GoogleHttpGateway(secrets),
    {clientId: secrets.clientId, redirectUri: secrets.redirectUri, encryptionKey: secrets.encryptionKey}
  );
}

export function syncService(secrets: GoogleCalendarSecrets) {
  const db = getFirestore();
  return new GoogleCalendarSyncService(new FirestoreSyncStore(db), new GoogleSyncHttpGateway(secrets), secrets.encryptionKey);
}

const APP_RETURN_URL = "sportscalendar://google-calendar/oauth-complete";
export function callbackHtml(success: boolean): string {
  const title = success ? "Google Calendarとの連携が完了しました" : "Google Calendarとの連携を完了できませんでした";
  const detail = success ? "アプリに戻ると同期を開始します。" : "アプリに戻って、もう一度お試しください。";
  return `<!doctype html><html lang="ja"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${title}</title><style>body{font-family:system-ui;margin:0;background:#f5f7fa;color:#182230}.card{max-width:34rem;margin:12vh auto;padding:2rem;background:white;border-radius:16px;box-shadow:0 4px 24px #0002}a{display:inline-block;margin-top:1rem;padding:.8rem 1.2rem;background:#1769aa;color:white;border-radius:9px;text-decoration:none}</style></head><body><main class="card"><h1>${title}</h1><p>${detail}</p><a href="${APP_RETURN_URL}">Sports Calendarに戻る</a><p><small>自動的に開かない場合は上のボタンを押してください。</small></p></main>${success ? `<script>setTimeout(function(){location.href=${JSON.stringify(APP_RETURN_URL)}},300)</script>` : ""}</body></html>`;
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
      const base = await service(secrets).status(uid);
      const connection = await new FirestoreConnectionStore(getFirestore()).getConnection(uid);
      return {...base, ...(connection?.lastSyncStatus ? {syncStatus: connection.lastSyncStatus} : {})};
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
        response.status(200).type("html").send(callbackHtml(true));
      } catch (error) {
        const code = error instanceof CalendarConnectionError ? error.code : "connection-failed";
        const status = ["malformed-callback", "invalid-or-expired-state", "oauth-denied"].includes(code) ? 400 : 502;
        console.warn("Google Calendar OAuth callback failed", {code});
        response.status(status).type("html").send(callbackHtml(false));
      }
    },
    sync: async (_data: unknown, context: functions.https.CallableContext) => {
      const uid = requireAuthenticatedUid(context);
      try { return await syncService(secrets).sync(uid); }
      catch (_) { throw new functions.https.HttpsError("unavailable", "google-calendar-sync-failed"); }
    },
  };
}

export async function syncAllActiveGoogleCalendars(secrets: GoogleCalendarSecrets) {
  const snapshot = await getFirestore().collection("googleCalendarConnections").where("status", "==", "active").get();
  const result = await syncUsersBounded(snapshot.docs.map(doc => doc.id), uid => syncService(secrets).sync(uid));
  console.info("Google Calendar batch reconciliation complete", result);
  return result;
}
