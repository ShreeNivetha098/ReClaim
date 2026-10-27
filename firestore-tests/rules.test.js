// Security-rule tests for firestore.rules, run against the local emulator.
// From the project root:
//   firebase emulators:exec --project demo-reclaim --only firestore "npm --prefix firestore-tests test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Bytes,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  writeBatch,
  collection,
} from 'firebase/firestore';

let env;

const STUDENT = 'student1';
const OTHER = 'student2';
const ADMIN = 'admin1';

const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-reclaim',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

// Fresh seed data for every test, written with rules switched off.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const fs = ctx.firestore();
    await setDoc(doc(fs, 'users', STUDENT), { uid: STUDENT, role: 'Student', isActive: true });
    await setDoc(doc(fs, 'users', OTHER), { uid: OTHER, role: 'Student', isActive: true });
    await setDoc(doc(fs, 'users', ADMIN), { uid: ADMIN, role: 'Admin', isActive: true });
    await setDoc(doc(fs, 'lostItems', 'lost1'), { ownerId: STUDENT, status: 'ACTIVE' });
    await setDoc(doc(fs, 'foundItems', 'found1'), { finderId: OTHER, status: 'ACTIVE' });
    await setDoc(doc(fs, 'claims', 'claim1'), { claimantId: STUDENT, status: 'PENDING' });
    await setDoc(doc(fs, 'notifications', 'n1'), {
      userId: STUDENT, title: 'Hi', body: 'Body', type: 'COMMON', isRead: false,
    });
    await setDoc(doc(fs, 'chats', 'chat1'), { participantIds: [STUDENT, OTHER] });
    await setDoc(doc(fs, 'chats', 'chat1', 'messages', 'm1'), {
      senderId: OTHER, text: 'Is this your bag?', isRead: false,
    });
  });
});

describe('users', () => {
  test('a new user cannot register as Admin', async () => {
    await assertFails(setDoc(doc(db('newUser'), 'users', 'newUser'), { role: 'Admin' }));
    await assertSucceeds(setDoc(doc(db('newUser'), 'users', 'newUser'), { role: 'Student' }));
  });

  test('a student cannot promote themselves to Admin', async () => {
    await assertFails(updateDoc(doc(db(STUDENT), 'users', STUDENT), { role: 'Admin' }));
  });

  test("a student cannot read someone else's profile", async () => {
    await assertFails(getDoc(doc(db(STUDENT), 'users', OTHER)));
    await assertSucceeds(getDoc(doc(db(STUDENT), 'users', STUDENT)));
  });
});

describe('lost and found reports', () => {
  test('a report cannot be created in someone else\'s name', async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'lostItems', 'x'), { ownerId: OTHER }));
    await assertFails(setDoc(doc(db(STUDENT), 'foundItems', 'y'), { finderId: OTHER }));
  });

  test("a student cannot edit or delete another student's report", async () => {
    await assertFails(updateDoc(doc(db(OTHER), 'lostItems', 'lost1'), { status: 'CLAIMED' }));
    await assertFails(deleteDoc(doc(db(OTHER), 'lostItems', 'lost1')));
    await assertFails(updateDoc(doc(db(STUDENT), 'foundItems', 'found1'), { status: 'CLAIMED' }));
  });

  test('an owner can update their report but not give it away', async () => {
    await assertSucceeds(updateDoc(doc(db(STUDENT), 'lostItems', 'lost1'), { status: 'RECOVERED' }));
    await assertFails(updateDoc(doc(db(STUDENT), 'lostItems', 'lost1'), { ownerId: OTHER }));
  });

  test('an admin can moderate any report', async () => {
    await assertSucceeds(updateDoc(doc(db(ADMIN), 'lostItems', 'lost1'), { status: 'UNCLAIMED' }));
    await assertSucceeds(deleteDoc(doc(db(ADMIN), 'foundItems', 'found1')));
  });
});

describe('claims', () => {
  test('a student cannot approve a claim', async () => {
    await assertFails(updateDoc(doc(db(STUDENT), 'claims', 'claim1'), { status: 'APPROVED' }));
    await assertSucceeds(updateDoc(doc(db(ADMIN), 'claims', 'claim1'), { status: 'APPROVED' }));
  });

  test('a claim cannot be filed for someone else', async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'claims', 'c2'), { claimantId: OTHER }));
  });
});

describe('notifications', () => {
  const notif = (overrides) => ({
    userId: OTHER, title: 'New Lost Item Reported', body: 'Body',
    type: 'COMMON', targetId: 'lost1', itemType: 'LOST', isRead: false, ...overrides,
  });

  test('a student cannot send an arbitrary notification to another user', async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'notifications', 'x'),
      notif({ type: 'CLAIM_APPROVED', title: 'Your claim was approved' })));
  });

  test('a student can broadcast about their own new report', async () => {
    await assertSucceeds(setDoc(doc(db(STUDENT), 'notifications', 'x'), notif({})));
  });

  test("a student cannot broadcast about someone else's report", async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'notifications', 'x'),
      notif({ targetId: 'found1', itemType: 'FOUND' })));
  });

  test('the broadcast batch the app sends on a new report is allowed', async () => {
    // The app commits up to 400 notifications per batch.
    const fs = db(STUDENT);
    const batch = writeBatch(fs);
    for (let i = 0; i < 400; i++) {
      batch.set(doc(collection(fs, 'notifications')), notif({ userId: `user${i}` }));
    }
    await assertSucceeds(batch.commit());
  });

  const match = (overrides) => ({
    userId: STUDENT, title: 'Possible match for your Wallet (80%)', body: 'Body',
    type: 'POTENTIAL_MATCH', targetId: 'found1', itemType: 'FOUND', lostItemId: 'lost1',
    isRead: false, ...overrides,
  });

  test('a finder can send a match notification to the lost report owner', async () => {
    await assertSucceeds(setDoc(doc(db(OTHER), 'notifications', 'match_lost1_found1'), match({})));
  });

  test('a match notification cannot go to someone who does not own the lost report', async () => {
    await assertFails(setDoc(doc(db(OTHER), 'notifications', 'x'), match({ userId: ADMIN })));
  });

  test("a match notification cannot be sent about someone else's found item", async () => {
    await assertFails(setDoc(doc(db('outsider'), 'notifications', 'x'), match({})));
  });

  test('the same match notification cannot be sent twice', async () => {
    const ref = (uid) => doc(db(uid), 'notifications', 'match_lost1_found1');
    await assertSucceeds(setDoc(ref(OTHER), match({})));
    await assertFails(setDoc(ref(OTHER), match({ title: 'again' })));
  });

  test('a claim notification to admin needs a claim the sender filed', async () => {
    const claimNotif = { userId: 'admin', type: 'CLAIM_SUBMITTED', title: 't', body: 'b', isRead: false };
    await assertSucceeds(setDoc(doc(db(STUDENT), 'notifications', 'x'), { ...claimNotif, targetId: 'claim1' }));
    await assertFails(setDoc(doc(db(OTHER), 'notifications', 'y'), { ...claimNotif, targetId: 'claim1' }));
  });

  test('a recipient can mark a notification read but not rewrite it', async () => {
    await assertSucceeds(updateDoc(doc(db(STUDENT), 'notifications', 'n1'), { isRead: true }));
    await assertFails(updateDoc(doc(db(STUDENT), 'notifications', 'n1'), { body: 'changed' }));
    await assertFails(updateDoc(doc(db(OTHER), 'notifications', 'n1'), { isRead: true }));
  });

  test("a student cannot read another user's notifications", async () => {
    await assertFails(getDoc(doc(db(OTHER), 'notifications', 'n1')));
  });
});

describe('chats and messages', () => {
  test('a student can start a chat that includes themselves', async () => {
    await assertSucceeds(setDoc(doc(db(STUDENT), 'chats', 'c2'), { participantIds: [STUDENT, OTHER] }));
  });

  test('a student cannot start a chat between other people', async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'chats', 'c2'), { participantIds: [OTHER, ADMIN] }));
  });

  test('outsiders cannot read a chat or its messages', async () => {
    await assertFails(getDoc(doc(db('outsider'), 'chats', 'chat1')));
    await assertFails(getDoc(doc(db('outsider'), 'chats', 'chat1', 'messages', 'm1')));
    await assertSucceeds(getDoc(doc(db(STUDENT), 'chats', 'chat1', 'messages', 'm1')));
  });

  test('participants can send messages only as themselves', async () => {
    const msgs = (uid) => collection(db(uid), 'chats', 'chat1', 'messages');
    await assertSucceeds(setDoc(doc(msgs(STUDENT)), { senderId: STUDENT, text: 'Yes, it is mine', isRead: false }));
    await assertFails(setDoc(doc(msgs(STUDENT)), { senderId: OTHER, text: 'spoofed', isRead: false }));
    await assertFails(setDoc(doc(msgs('outsider')), { senderId: 'outsider', text: 'hi', isRead: false }));
  });

  test('participants cannot be changed after a chat starts', async () => {
    await assertFails(updateDoc(doc(db(STUDENT), 'chats', 'chat1'), { participantIds: [STUDENT, 'outsider'] }));
  });

  test('the old top-level messages collection is closed', async () => {
    await assertFails(setDoc(doc(db(STUDENT), 'messages', 'x'), { senderId: STUDENT, text: 'hi' }));
  });
});

describe('activity logs', () => {
  test('only admins can write or read the activity log', async () => {
    const log = { actorId: STUDENT, action: 'CLAIM_APPROVED' };
    await assertFails(setDoc(doc(db(STUDENT), 'activityLogs', 'l1'), log));
    await assertSucceeds(setDoc(doc(db(ADMIN), 'activityLogs', 'l2'), { ...log, actorId: ADMIN }));
    await assertFails(getDoc(doc(db(STUDENT), 'activityLogs', 'l2')));
  });
});

describe('item photos', () => {
  test('photos over the size limit are refused', async () => {
    const small = Bytes.fromUint8Array(new Uint8Array(1024));
    const big = Bytes.fromUint8Array(new Uint8Array(901 * 1024));
    await assertSucceeds(setDoc(doc(db(STUDENT), 'itemImages', 'p1'), { uploaderId: STUDENT, data: small }));
    await assertFails(setDoc(doc(db(STUDENT), 'itemImages', 'p2'), { uploaderId: STUDENT, data: big }));
  });
});
