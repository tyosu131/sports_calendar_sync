import { randomBytes } from "node:crypto";

export interface CalendarFeedRecord {
  ownerUid: string;
  active: boolean;
  createdAt: Date;
  rotatedAt?: Date;
}

export interface CalendarFeedRepository {
  /** Implementations must serialize this operation for a given owner. */
  transact<T>(ownerUid: string, operation: (transaction: CalendarFeedTransaction) => Promise<T>): Promise<T>;
}

export interface CalendarFeedTransaction {
  getActiveToken(): Promise<string | undefined>;
  tokenExists(token: string): Promise<boolean>;
  create(token: string, record: CalendarFeedRecord): void;
  deactivate(token: string, rotatedAt: Date): void;
  setActiveToken(token: string): void;
}

export type TokenFactory = () => string;

/** 32 random bytes = 256 bits; base64url contains no URL-reserved characters. */
export const generateCalendarFeedToken: TokenFactory = () => randomBytes(32).toString("base64url");

export class CalendarFeedService {
  constructor(
    private readonly repository: CalendarFeedRepository,
    private readonly tokenFactory: TokenFactory = generateCalendarFeedToken,
    private readonly now: () => Date = () => new Date()
  ) {}

  ensure(ownerUid: string): Promise<string> {
    return this.repository.transact(ownerUid, async (transaction) => {
      const current = await transaction.getActiveToken();
      if (current) return current;
      return this.issue(transaction, ownerUid);
    });
  }

  rotate(ownerUid: string): Promise<string> {
    return this.repository.transact(ownerUid, async (transaction) => {
      const current = await transaction.getActiveToken();
      const rotatedAt = this.now();
      const next = await this.issue(transaction, ownerUid, rotatedAt);
      if (current) transaction.deactivate(current, rotatedAt);
      return next;
    });
  }

  private async issue(transaction: CalendarFeedTransaction, ownerUid: string, now = this.now()): Promise<string> {
    // A collision is extraordinarily unlikely, but must never overwrite another feed.
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const token = this.tokenFactory();
      if (!token || await transaction.tokenExists(token)) continue;
      transaction.create(token, { ownerUid, active: true, createdAt: now });
      transaction.setActiveToken(token);
      return token;
    }
    throw new Error("Unable to allocate a unique calendar feed credential");
  }
}
