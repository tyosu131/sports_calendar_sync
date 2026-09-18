import * as functions from "firebase-functions/v1";
import { FieldValue, Firestore, Transaction, getFirestore } from "firebase-admin/firestore";
import {
  CalendarFeedRepository,
  CalendarFeedService,
  CalendarFeedTransaction,
  CalendarFeedRecord,
} from "../calendar/feedService";

class FirestoreFeedRepository implements CalendarFeedRepository {
  constructor(private readonly db: Firestore) {}

  transact<T>(ownerUid: string, operation: (transaction: CalendarFeedTransaction) => Promise<T>): Promise<T> {
    return this.db.runTransaction(async (firestoreTransaction) => {
      const transaction = new FirestoreFeedTransaction(this.db, firestoreTransaction, ownerUid);
      return operation(transaction);
    });
  }
}

class FirestoreFeedTransaction implements CalendarFeedTransaction {
  private readonly ownerRef;

  constructor(
    private readonly db: Firestore,
    private readonly transaction: Transaction,
    ownerUid: string
  ) {
    // This private pointer makes issuance and rotation atomic per authenticated user.
    this.ownerRef = db.collection("calendarFeedOwners").doc(ownerUid);
  }

  async getActiveToken(): Promise<string | undefined> {
    const owner = await this.transaction.get(this.ownerRef);
    const token = owner.get("activeToken");
    if (typeof token !== "string") return undefined;
    const feed = await this.transaction.get(this.db.collection("calendarFeeds").doc(token));
    return feed.exists && feed.get("active") === true ? token : undefined;
  }

  async tokenExists(token: string): Promise<boolean> {
    return (await this.transaction.get(this.db.collection("calendarFeeds").doc(token))).exists;
  }

  create(token: string, record: CalendarFeedRecord): void {
    this.transaction.create(this.db.collection("calendarFeeds").doc(token), {
      ...record,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  deactivate(token: string, _rotatedAt: Date): void {
    this.transaction.update(this.db.collection("calendarFeeds").doc(token), {
      active: false,
      rotatedAt: FieldValue.serverTimestamp(),
    });
  }

  setActiveToken(token: string): void {
    this.transaction.set(this.ownerRef, { activeToken: token }, { merge: true });
  }
}

export function requireAuthenticatedUid(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }
  return context.auth.uid;
}

function service(): CalendarFeedService {
  return new CalendarFeedService(new FirestoreFeedRepository(getFirestore()));
}

export const ensureCalendarFeed = functions.region("asia-northeast1").https.onCall(
  async (_data: unknown, context) => ({ token: await service().ensure(requireAuthenticatedUid(context)) })
);

export const rotateCalendarFeed = functions.region("asia-northeast1").https.onCall(
  async (_data: unknown, context) => ({ token: await service().rotate(requireAuthenticatedUid(context)) })
);
