const fs = require("fs");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const PROJECT_ID = "rosary-guide-rules-test";
const RULES = fs.readFileSync("firestore.rules", "utf8");
const VALID_ID = "11111111-1111-4111-8111-111111111111";

function validIntention(overrides = {}) {
  return {
    schemaVersion: 1,
    title: "For Mum",
    timesCarried: 0,
    isPinned: false,
    createdAt: new Date("2026-09-26T00:00:00Z"),
    category: "personal",
    accent: "skyBlue",
    suggestOn: ["glorious"],
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function validPreferences(overrides = {}) {
  return {
    schemaVersion: 1,
    appearance: "dark",
    prayerLanguage: "english",
    rosaryLanguage: "english",
    textSize: "medium",
    includeSaintMichael: false,
    hideIntentionText: true,
    dailyReminderEnabled: true,
    dailyReminderMinutes: 19 * 60,
    feastAlertsEnabled: false,
    appIcon: "blue",
    updatedAt: new Date(),
    ...overrides,
  };
}

function validSession(overrides = {}) {
  return {
    mysterySet: "joyful",
    stepIndex: 12,
    startedAt: new Date(),
    updatedAt: new Date(),
    includeSaintMichael: false,
    language: "bilingual",
    intentionId: VALID_ID,
    intentionTitle: "For Mum",
    ...overrides,
  };
}

function validProgress(overrides = {}) {
  return {
    schemaVersion: 1,
    completedDays: ["2026-10-03", "2026-10-04"],
    session: validSession(),
    sessionChangedAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function withoutKey(object, key) {
  const copy = { ...object };
  delete copy[key];
  return copy;
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: RULES,
      host: "127.0.0.1",
      port: 8080,
    },
  });

  try {
    const alice = testEnv.authenticatedContext("alice").firestore();
    const bob = testEnv.authenticatedContext("bob").firestore();
    const anon = testEnv.unauthenticatedContext().firestore();
    const aliceDoc = doc(alice, "users/alice/intentions", VALID_ID);
    const bobDocFromAlice = doc(alice, "users/bob/intentions", VALID_ID);

    await assertFails(getDoc(doc(anon, "users/alice/intentions", VALID_ID)));
    await assertSucceeds(setDoc(aliceDoc, validIntention()));
    await assertSucceeds(getDoc(aliceDoc));
    await assertSucceeds(getDocs(collection(alice, "users/alice/intentions")));

    await assertFails(getDoc(doc(bob, "users/alice/intentions", VALID_ID)));
    await assertFails(getDocs(collection(bob, "users/alice/intentions")));
    await assertFails(setDoc(bobDocFromAlice, validIntention()));
    await assertFails(updateDoc(bobDocFromAlice, { title: "Stolen" }));
    await assertFails(deleteDoc(bobDocFromAlice));

    await assertFails(setDoc(doc(alice, "users/alice/intentions", "not-a-uuid"), validIntention()));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "22222222-2222-4222-8222-222222222222"), validIntention({ ownerUid: "alice" })));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "33333333-3333-4333-8333-333333333333"), validIntention({ title: "" })));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "44444444-4444-4444-8444-444444444444"), validIntention({ note: "x".repeat(2001) })));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "55555555-5555-4555-8555-555555555555"), validIntention({ timesCarried: -1 })));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "66666666-6666-4666-8666-666666666666"), validIntention({ category: "admin" })));
    await assertFails(setDoc(doc(alice, "users/alice/intentions", "77777777-7777-4777-8777-777777777777"), validIntention({ suggestOn: ["unknown"] })));
    // Preferences and progress
    const prefs = doc(alice, "users/alice/meta/preferences");
    const progress = doc(alice, "users/alice/meta/progress");
    const farFuture = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

    await assertFails(getDoc(doc(anon, "users/alice/meta/preferences")));
    await assertSucceeds(getDoc(prefs));
    await assertSucceeds(setDoc(prefs, validPreferences()));
    await assertSucceeds(setDoc(prefs, validPreferences({ appIcon: "white", dailyReminderMinutes: 0 })));
    await assertSucceeds(getDoc(prefs));
    await assertFails(getDoc(doc(bob, "users/alice/meta/preferences")));
    await assertFails(setDoc(doc(bob, "users/alice/meta/preferences"), validPreferences()));
    await assertFails(deleteDoc(doc(bob, "users/alice/meta/preferences")));
    await assertFails(setDoc(prefs, validPreferences({ isAdmin: true })));
    await assertFails(setDoc(prefs, withoutKey(validPreferences(), "appIcon")));
    await assertFails(setDoc(prefs, validPreferences({ appearance: "neon" })));
    await assertFails(setDoc(prefs, validPreferences({ dailyReminderMinutes: 1440 })));
    await assertFails(setDoc(prefs, validPreferences({ dailyReminderMinutes: "19:00" })));
    await assertFails(setDoc(prefs, validPreferences({ hideIntentionText: "yes" })));
    await assertFails(setDoc(prefs, validPreferences({ updatedAt: farFuture })));
    await assertFails(setDoc(prefs, validPreferences({ schemaVersion: 2 })));
    await assertFails(setDoc(doc(alice, "users/alice/meta/other"), validPreferences()));
    await assertFails(getDoc(doc(alice, "users/alice/meta/other")));
    await assertFails(getDocs(collection(alice, "users/alice/meta")));

    await assertSucceeds(setDoc(progress, validProgress()));
    await assertSucceeds(setDoc(progress, validProgress({ completedDays: [], historyResetAt: new Date() })));
    await assertSucceeds(setDoc(progress, withoutKey(validProgress(), "session")));
    await assertSucceeds(setDoc(progress, validProgress({ session: withoutKey(withoutKey(validSession(), "intentionId"), "intentionTitle") })));
    await assertSucceeds(setDoc(progress, validProgress({ sessionChangedAt: new Date(0) })));
    await assertFails(setDoc(doc(bob, "users/alice/meta/progress"), validProgress()));
    await assertFails(setDoc(progress, validProgress({ completedDays: ["2026-10-04", "x".repeat(500)] })));
    await assertFails(setDoc(progress, validProgress({ completedDays: ["2026-10-04", 5] })));
    await assertFails(setDoc(progress, validProgress({ completedDays: Array.from({ length: 401 }, () => "2026-01-01") })));
    await assertFails(setDoc(progress, validProgress({ completedDays: "2026-10-04" })));
    await assertFails(setDoc(progress, validProgress({ streak: 4 })));
    await assertFails(setDoc(progress, validProgress({ session: validSession({ stepIndex: 501 }) })));
    await assertFails(setDoc(progress, validProgress({ session: validSession({ mysterySet: "other" }) })));
    await assertFails(setDoc(progress, validProgress({ session: validSession({ intentionId: "nope" }) })));
    await assertFails(setDoc(progress, validProgress({ session: validSession({ intentionTitle: "x".repeat(161) }) })));
    await assertFails(setDoc(progress, validProgress({ session: validSession({ extra: 1 }) })));
    await assertFails(setDoc(progress, validProgress({ updatedAt: farFuture })));
    await assertFails(setDoc(progress, withoutKey(validProgress(), "sessionChangedAt")));

    await assertFails(deleteDoc(doc(alice, "users/alice/meta/other")));
    await assertSucceeds(deleteDoc(prefs));
    await assertSucceeds(deleteDoc(progress));

    await assertSucceeds(deleteDoc(aliceDoc));
    console.log("All Firestore rules tests passed.");
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
