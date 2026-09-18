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
Object.defineProperty(exports, "__esModule", { value: true });
exports.rotateCalendarFeed = exports.ensureCalendarFeed = void 0;
exports.requireAuthenticatedUid = requireAuthenticatedUid;
const functions = __importStar(require("firebase-functions/v1"));
const firestore_1 = require("firebase-admin/firestore");
const feedService_1 = require("../calendar/feedService");
class FirestoreFeedRepository {
    constructor(db) {
        this.db = db;
    }
    transact(ownerUid, operation) {
        return this.db.runTransaction(async (firestoreTransaction) => {
            const transaction = new FirestoreFeedTransaction(this.db, firestoreTransaction, ownerUid);
            return operation(transaction);
        });
    }
}
class FirestoreFeedTransaction {
    constructor(db, transaction, ownerUid) {
        this.db = db;
        this.transaction = transaction;
        // This private pointer makes issuance and rotation atomic per authenticated user.
        this.ownerRef = db.collection("calendarFeedOwners").doc(ownerUid);
    }
    async getActiveToken() {
        const owner = await this.transaction.get(this.ownerRef);
        const token = owner.get("activeToken");
        if (typeof token !== "string")
            return undefined;
        const feed = await this.transaction.get(this.db.collection("calendarFeeds").doc(token));
        return feed.exists && feed.get("active") === true ? token : undefined;
    }
    async tokenExists(token) {
        return (await this.transaction.get(this.db.collection("calendarFeeds").doc(token))).exists;
    }
    create(token, record) {
        this.transaction.create(this.db.collection("calendarFeeds").doc(token), {
            ...record,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    deactivate(token, _rotatedAt) {
        this.transaction.update(this.db.collection("calendarFeeds").doc(token), {
            active: false,
            rotatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    }
    setActiveToken(token) {
        this.transaction.set(this.ownerRef, { activeToken: token }, { merge: true });
    }
}
function requireAuthenticatedUid(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required");
    }
    return context.auth.uid;
}
function service() {
    return new feedService_1.CalendarFeedService(new FirestoreFeedRepository((0, firestore_1.getFirestore)()));
}
exports.ensureCalendarFeed = functions.region("asia-northeast1").https.onCall(async (_data, context) => ({ token: await service().ensure(requireAuthenticatedUid(context)) }));
exports.rotateCalendarFeed = functions.region("asia-northeast1").https.onCall(async (_data, context) => ({ token: await service().rotate(requireAuthenticatedUid(context)) }));
//# sourceMappingURL=calendarFeeds.js.map