import { createCipheriv, randomBytes } from "crypto";

export const GOOGLE_CALENDAR_SCOPE =
  "https://www.googleapis.com/auth/calendar.app.created";
export const CALENDAR_NAME = "Sports Calendar";
export const CALENDAR_MARKER = "sports-calendar-sync:app-created";

export type Connection = {
  status: "active" | "disconnected";
  calendarId?: string;
  grantedScopes?: string[];
};

export interface ConnectionStore {
  createState(hash: string, uid: string, expiresAt: Date): Promise<void>;
  consumeState(hash: string, now: Date): Promise<string | undefined>;
  getConnection(uid: string): Promise<Connection | undefined>;
  saveConnection(uid: string, value: Connection): Promise<void>;
  saveCredential(uid: string, value: EncryptedCredential): Promise<void>;
  deleteCredential(uid: string): Promise<void>;
}

export interface GoogleGateway {
  exchangeCode(code: string): Promise<{refreshToken?: string; scopes: string[]}>;
  createCalendar(refreshToken: string): Promise<string>;
}

export type EncryptedCredential = {
  algorithm: "aes-256-gcm";
  ciphertext: string;
  iv: string;
  authTag: string;
};

export class CalendarConnectionError extends Error {
  constructor(readonly code: string) { super(code); }
}

export function encryptRefreshToken(token: string, base64Key: string): EncryptedCredential {
  const key = Buffer.from(base64Key, "base64");
  if (key.length !== 32) throw new CalendarConnectionError("invalid-encryption-key");
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  const ciphertext = Buffer.concat([cipher.update(token, "utf8"), cipher.final()]);
  return {
    algorithm: "aes-256-gcm",
    ciphertext: ciphertext.toString("base64"),
    iv: iv.toString("base64"),
    authTag: cipher.getAuthTag().toString("base64"),
  };
}

export class GoogleCalendarConnectionService {
  constructor(
    private readonly store: ConnectionStore,
    private readonly google: GoogleGateway,
    private readonly config: {clientId: string; redirectUri: string; encryptionKey: string},
    private readonly now = () => new Date(),
    private readonly random = () => randomBytes(32).toString("base64url")
  ) {}

  async begin(uid: string): Promise<string> {
    const state = this.random();
    const expiresAt = new Date(this.now().getTime() + 10 * 60 * 1000);
    await this.store.createState(hashState(state), uid, expiresAt);
    const query = new URLSearchParams({
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      response_type: "code",
      scope: GOOGLE_CALENDAR_SCOPE,
      access_type: "offline",
      include_granted_scopes: "true",
      prompt: "consent",
      state,
    });
    return `https://accounts.google.com/o/oauth2/v2/auth?${query}`;
  }

  async callback(input: {state?: string; code?: string; error?: string}): Promise<void> {
    if (!input.state) throw new CalendarConnectionError("malformed-callback");
    const uid = await this.store.consumeState(hashState(input.state), this.now());
    if (!uid) throw new CalendarConnectionError("invalid-or-expired-state");
    if (input.error) throw new CalendarConnectionError("oauth-denied");
    if (!input.code) throw new CalendarConnectionError("malformed-callback");

    let token;
    try { token = await this.google.exchangeCode(input.code); }
    catch (_) { throw new CalendarConnectionError("token-exchange-failed"); }
    if (!token.refreshToken) throw new CalendarConnectionError("missing-refresh-token");

    const previous = await this.store.getConnection(uid);
    let calendarId = previous?.calendarId;
    try {
      calendarId = calendarId ?? await this.google.createCalendar(token.refreshToken);
    } catch (error) {
      if (error instanceof CalendarConnectionError) throw error;
      throw new CalendarConnectionError("calendar-creation-failed");
    }

    await this.store.saveCredential(uid, encryptRefreshToken(token.refreshToken, this.config.encryptionKey));
    await this.store.saveConnection(uid, {
      status: "active", calendarId, grantedScopes: token.scopes,
    });
  }

  async status(uid: string): Promise<{connected: boolean; calendarName?: string}> {
    const connection = await this.store.getConnection(uid);
    return connection?.status === "active"
      ? {connected: true, calendarName: CALENDAR_NAME}
      : {connected: false};
  }

  async disconnect(uid: string): Promise<void> {
    const existing = await this.store.getConnection(uid);
    await this.store.deleteCredential(uid);
    await this.store.saveConnection(uid, {...existing, status: "disconnected"});
  }
}

import { createHash } from "crypto";
function hashState(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}
