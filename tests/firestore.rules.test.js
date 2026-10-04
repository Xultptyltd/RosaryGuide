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
    await assertSucceeds(deleteDoc(aliceDoc));
  } finally {
    await testEnv.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
