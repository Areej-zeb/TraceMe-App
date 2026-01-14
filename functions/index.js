const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger Lost Mode for a target device.
 * 1. Checks requester ownership.
 * 2. Updates device status to LOST.
 * 3. Creates a START_LOST_MODE command.
 * 4. Sends FCM data message.
 */
exports.triggerLostMode = functions.https.onCall(async (data, context) => {
  // 1. Auth & Validation
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetDeviceId = data.targetDeviceId;
  if (!targetDeviceId) {
    throw new functions.https.HttpsError("invalid-argument", "targetDeviceId is required.");
  }

  const requesterUid = context.auth.uid;
  const docRef = db.collection("devices").doc(targetDeviceId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Device not found.");
  }

  const deviceData = doc.data();
  if (deviceData.ownerUid !== requesterUid) {
    throw new functions.https.HttpsError("permission-denied", "You do not own this device.");
  }

  // 2. Update Status to LOST
  const now = admin.firestore.Timestamp.now();
  await docRef.update({
    status: "LOST",
    "lostMode.enabled": true,
    "lostMode.enabledAt": now,
    "lostMode.enabledByUid": requesterUid
  });

  // 3. Create Command
  const commandRef = db.collection("commands").doc();
  const commandId = commandRef.id;
  await commandRef.set({
    targetDeviceId: targetDeviceId,
    createdByUid: requesterUid,
    type: "START_LOST_MODE",
    createdAt: now,
    status: "SENT"
  });

  // 4. Send FCM Push (Data Message)
  const fcmToken = deviceData.fcmToken;
  if (fcmToken) {
    try {
      await admin.messaging().send({
        token: fcmToken,
        data: {
          command: "START_LOST_MODE",
          commandId: commandId,
          targetDeviceId: targetDeviceId,
          timestamp: now.toMillis().toString() // Convert to string for FCM data
        }
      });
      console.log(`FCM sent to ${targetDeviceId}`);
    } catch (e) {
      console.error(`Error sending FCM to ${targetDeviceId}:`, e);
      // We don't fail the function because Firestore status is the source of truth.
      await commandRef.update({ status: "SENT_BUT_FCM_FAILED", error: e.message });
    }
  } else {
    console.log(`No FCM token for ${targetDeviceId}`);
    await commandRef.update({ status: "SENT_NO_TOKEN" });
  }

  return { success: true, message: "Lost Mode Triggered", commandId: commandId };
});

/**
 * Stop Lost Mode for a target device.
 */
exports.stopLostMode = functions.https.onCall(async (data, context) => {
  // 1. Auth & Validation
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetDeviceId = data.targetDeviceId;
  if (!targetDeviceId) {
    throw new functions.https.HttpsError("invalid-argument", "targetDeviceId is required.");
  }

  const requesterUid = context.auth.uid;
  const docRef = db.collection("devices").doc(targetDeviceId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Device not found.");
  }

  const deviceData = doc.data();
  if (deviceData.ownerUid !== requesterUid) {
    throw new functions.https.HttpsError("permission-denied", "You do not own this device.");
  }

  // 2. Update Status to ACTIVE
  const now = admin.firestore.Timestamp.now();
  await docRef.update({
    status: "ACTIVE",
    "lostMode.enabled": false,
    "lostMode.disabledAt": now
  });

  // 3. Create Command
  const commandRef = db.collection("commands").doc();
  await commandRef.set({
    targetDeviceId: targetDeviceId,
    createdByUid: requesterUid,
    type: "STOP_LOST_MODE",
    createdAt: now,
    status: "SENT"
  });

  // 4. Send FCM Push (Data Message)
  const fcmToken = deviceData.fcmToken;
  if (fcmToken) {
    try {
      await admin.messaging().send({
        token: fcmToken,
        data: {
          command: "STOP_LOST_MODE",
          targetDeviceId: targetDeviceId
        }
      });
    } catch (e) {
      console.error(`Error sending STOP FCM to ${targetDeviceId}:`, e);
    }
  }

  return { success: true, message: "Lost Mode Stopped" };
});

/**
 * Register or Update Device Token.
 * Allows client to update its own FCM token and basic info.
 */
exports.registerDevice = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const { deviceId, deviceName, fcmToken, platform } = data;
  if (!deviceId || !fcmToken) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }

  // Ensure user isn't overwriting someone else's device
  const docRef = db.collection("devices").doc(deviceId);
  const doc = await docRef.get();

  if (doc.exists && doc.data().ownerUid !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "Device already registered to another user.");
  }

  await docRef.set({
    ownerUid: context.auth.uid,
    deviceName: deviceName || "Unknown Device",
    fcmToken: fcmToken,
    platform: platform || "unknown",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    // Initialize defaults if new
    status: doc.exists ? doc.data().status : "ACTIVE",
    lostMode: doc.exists ? (doc.data().lostMode || { enabled: false }) : { enabled: false }
  }, { merge: true });

  return { success: true };
});

/**
 * Trigger Ring on a target device.
 */
exports.triggerRing = functions.https.onCall(async (data, context) => {
  // 1. Auth & Validation
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetDeviceId = data.targetDeviceId;
  if (!targetDeviceId) {
    throw new functions.https.HttpsError("invalid-argument", "targetDeviceId is required.");
  }

  const requesterUid = context.auth.uid;
  const docRef = db.collection("devices").doc(targetDeviceId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Device not found.");
  }

  const deviceData = doc.data();
  if (deviceData.ownerUid !== requesterUid) {
    throw new functions.https.HttpsError("permission-denied", "You do not own this device.");
  }

  // 2. Create Command
  const now = admin.firestore.Timestamp.now();
  const commandRef = db.collection("commands").doc();
  const commandId = commandRef.id;
  await commandRef.set({
    targetDeviceId: targetDeviceId,
    createdByUid: requesterUid,
    type: "START_RING",
    createdAt: now,
    status: "SENT"
  });

  // 3. Send FCM Push (Data Message)
  const fcmToken = deviceData.fcmToken;
  if (fcmToken) {
    try {
      await admin.messaging().send({
        token: fcmToken,
        data: {
          command: "RING",
          commandId: commandId,
          targetDeviceId: targetDeviceId
        },
        android: {
          priority: "high", // Ensure high priority for immediate delivery
        },
        apns: {
          payload: {
            aps: {
              "content-available": 1, // Wake up app on iOS
            }
          }
        }
      });
    } catch (e) {
      console.error(`Error sending RING FCM to ${targetDeviceId}:`, e);
      await commandRef.update({ status: "SENT_BUT_FCM_FAILED", error: e.message });
    }
  } else {
    await commandRef.update({ status: "SENT_NO_TOKEN" });
  }

  return { success: true, message: "Ring Triggered", commandId: commandId };
});

/**
 * Stop Ring on a target device.
 */
exports.stopRing = functions.https.onCall(async (data, context) => {
  // 1. Auth & Validation
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetDeviceId = data.targetDeviceId;
  if (!targetDeviceId) {
    throw new functions.https.HttpsError("invalid-argument", "targetDeviceId is required.");
  }

  const requesterUid = context.auth.uid;
  const docRef = db.collection("devices").doc(targetDeviceId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new functions.https.HttpsError("not-found", "Device not found.");
  }

  const deviceData = doc.data();
  if (deviceData.ownerUid !== requesterUid) {
    throw new functions.https.HttpsError("permission-denied", "You do not own this device.");
  }

  // 2. Create Command
  const now = admin.firestore.Timestamp.now();
  const commandRef = db.collection("commands").doc();
  await commandRef.set({
    targetDeviceId: targetDeviceId,
    createdByUid: requesterUid,
    type: "STOP_RING",
    createdAt: now,
    status: "SENT"
  });

  // 3. Send FCM Push (Data Message)
  const fcmToken = deviceData.fcmToken;
  if (fcmToken) {
    try {
      await admin.messaging().send({
        token: fcmToken,
        data: {
          command: "STOP_RING",
          targetDeviceId: targetDeviceId
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              "content-available": 1,
            }
          }
        }
      });
    } catch (e) {
      console.error(`Error sending STOP_RING FCM to ${targetDeviceId}:`, e);
    }
  }

  return { success: true, message: "Ring Stopped" };
});
