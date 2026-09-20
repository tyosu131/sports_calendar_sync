import { CalendarGame } from "../calendar/icsBuilder";
import { Connection, EncryptedCredential, CalendarConnectionError, decryptRefreshToken } from "./connectionService";
import { ReconcileGateway, ReconcileSummary, reconcileEvents } from "./reconciliation";

export type SyncStatus = "synced" | "error" | "reauth_required";
export interface SyncResult extends ReconcileSummary {status: SyncStatus; calendarRecreated: boolean}

export interface SyncStore {
  getConnection(uid: string): Promise<Connection | undefined>;
  getCredential(uid: string): Promise<EncryptedCredential | undefined>;
  getGames(uid: string): Promise<readonly CalendarGame[]>;
  updateCalendar(uid: string, calendarId: string): Promise<void>;
  record(uid: string, result: {status: SyncStatus; errorCode?: string; summary?: ReconcileSummary; calendarRecreated?: boolean}): Promise<void>;
  requireReauth(uid: string): Promise<void>;
}

export interface SyncGoogleGateway {
  refresh(refreshToken: string): Promise<string>;
  calendarUsable(accessToken: string, calendarId: string): Promise<boolean>;
  createCalendar(accessToken: string): Promise<string>;
  events(accessToken: string): ReconcileGateway;
}

export class CredentialError extends Error {
  constructor(readonly permanent: boolean, readonly code: string) { super(code); }
}

export class GoogleCalendarSyncService {
  constructor(private store: SyncStore, private google: SyncGoogleGateway, private encryptionKey: string) {}

  async sync(uid: string): Promise<SyncResult> {
    const connection = await this.store.getConnection(uid);
    if (connection?.status !== "active" || !connection.calendarId) throw new CalendarConnectionError("not-connected");
    try {
      const encrypted = await this.store.getCredential(uid);
      if (!encrypted) throw new CredentialError(true, "credential-missing");
      const refreshToken = decryptRefreshToken(encrypted, this.encryptionKey);
      const accessToken = await this.google.refresh(refreshToken);
      let calendarId = connection.calendarId;
      let calendarRecreated = false;
      if (!await this.google.calendarUsable(accessToken, calendarId)) {
        calendarId = await this.google.createCalendar(accessToken);
        await this.store.updateCalendar(uid, calendarId);
        calendarRecreated = true;
      }
      const summary = await reconcileEvents(this.google.events(accessToken), calendarId, await this.store.getGames(uid));
      const result = {status: "synced" as const, ...summary, calendarRecreated};
      await this.store.record(uid, {status: result.status, summary, calendarRecreated});
      return result;
    } catch (error) {
      const permanent = error instanceof CredentialError && error.permanent ||
        error instanceof CalendarConnectionError && error.code === "invalid-encrypted-credential";
      const code = permanent ? "reauth-required" : error instanceof CredentialError ? error.code : "provider-error";
      if (permanent) await this.store.requireReauth(uid);
      await this.store.record(uid, {status: permanent ? "reauth_required" : "error", errorCode: code});
      if (permanent) return {status: "reauth_required", created: 0, updated: 0, deleted: 0, unchanged: 0, calendarRecreated: false};
      throw error;
    }
  }
}

/** Quota-safe batch runner: no more than `concurrency` users are in flight. */
export async function syncUsersBounded(uids: readonly string[], sync: (uid: string) => Promise<unknown>, concurrency = 3) {
  let cursor = 0; let synced = 0; let failed = 0;
  const worker = async () => { while (cursor < uids.length) { const uid = uids[cursor++]; try { await sync(uid); synced++; } catch (_) { failed++; } } };
  await Promise.all(Array.from({length: Math.min(concurrency, uids.length)}, worker));
  return {considered: uids.length, synced, failed};
}
