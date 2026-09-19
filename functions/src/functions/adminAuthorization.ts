import * as functions from "firebase-functions/v1";

export function requireAdmin(context: Pick<functions.https.CallableContext, "auth">): void {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Administrator claim required");
  }
}
