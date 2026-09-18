"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CalendarFeedService = exports.generateCalendarFeedToken = void 0;
const node_crypto_1 = require("node:crypto");
/** 32 random bytes = 256 bits; base64url contains no URL-reserved characters. */
const generateCalendarFeedToken = () => (0, node_crypto_1.randomBytes)(32).toString("base64url");
exports.generateCalendarFeedToken = generateCalendarFeedToken;
class CalendarFeedService {
    constructor(repository, tokenFactory = exports.generateCalendarFeedToken, now = () => new Date()) {
        this.repository = repository;
        this.tokenFactory = tokenFactory;
        this.now = now;
    }
    ensure(ownerUid) {
        return this.repository.transact(ownerUid, async (transaction) => {
            const current = await transaction.getActiveToken();
            if (current)
                return current;
            return this.issue(transaction, ownerUid);
        });
    }
    rotate(ownerUid) {
        return this.repository.transact(ownerUid, async (transaction) => {
            const current = await transaction.getActiveToken();
            const rotatedAt = this.now();
            const next = await this.issue(transaction, ownerUid, rotatedAt);
            if (current)
                transaction.deactivate(current, rotatedAt);
            return next;
        });
    }
    async issue(transaction, ownerUid, now = this.now()) {
        // A collision is extraordinarily unlikely, but must never overwrite another feed.
        for (let attempt = 0; attempt < 5; attempt += 1) {
            const token = this.tokenFactory();
            if (!token || await transaction.tokenExists(token))
                continue;
            transaction.create(token, { ownerUid, active: true, createdAt: now });
            transaction.setActiveToken(token);
            return token;
        }
        throw new Error("Unable to allocate a unique calendar feed credential");
    }
}
exports.CalendarFeedService = CalendarFeedService;
//# sourceMappingURL=feedService.js.map