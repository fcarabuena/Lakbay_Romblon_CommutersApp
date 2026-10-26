'use strict';

// Security rule tests. They need the Firestore and Storage emulators:
//   firebase emulators:exec --only firestore,storage --project demo-lakbay \
//     "npm test --prefix firebase/rules-test"

const { readFileSync } = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp,
  collection, query, where, getDocs,
} = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');

const root = path.join(__dirname, '..');
const DAY = Math.floor(Date.now() / 86400000);

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lakbay',
    firestore: { rules: readFileSync(path.join(root, 'firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(path.join(root, 'storage.rules'), 'utf8') },
  });
});

test.after(() => env.cleanup());

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'admins/admin1'), { role: 'admin', email: 'a@example.com' });
    await setDoc(doc(db, 'admins/editor1'), { role: 'editor', email: 'e@example.com' });
    await setDoc(doc(db, 'ports/p1'), { id: 'p1', name: 'Port 1', updatedAt: new Date() });
    await setDoc(doc(db, 'audit_log/old'), { uid: 'admin1', collection: 'ports', docId: 'p1' });
    await setDoc(doc(db, 'reports/existing_1_1'), {
      kind: 'other', status: 'pending', reporterUid: 'anon1', note: 'n',
    });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

function auditedBatch(db, uid, { collectionName = 'ports', docId = 'p1', data = {}, auditFor } = {}) {
  const auditId = `audit-${Math.random().toString(36).slice(2)}`;
  const batch = writeBatch(db);
  batch.set(doc(db, `${collectionName}/${docId}`), {
    id: docId, name: 'Edited', ...data,
    updatedAt: serverTimestamp(), updatedBy: uid, auditId,
  });
  const target = auditFor || { collection: collectionName, docId };
  batch.set(doc(db, `audit_log/${auditId}`), {
    uid, email: 'x@example.com', action: 'update', at: serverTimestamp(),
    collection: target.collection, docId: target.docId, before: null, after: null,
  });
  return batch;
}

// ---------- travel data ----------

test('anyone can read travel data', async () => {
  await assertSucceeds(getDoc(doc(anon(), 'ports/p1')));
  await assertSucceeds(getDoc(doc(anon(), 'config/meta')));
});

test('unknown collections are not readable', async () => {
  await assertFails(getDoc(doc(anon(), 'secrets/x')));
});

test('an editor can write with an audit entry in the same batch', async () => {
  await assertSucceeds(auditedBatch(as('editor1'), 'editor1').commit());
  await assertSucceeds(
    auditedBatch(as('admin1'), 'admin1', { collectionName: 'advisories', docId: 'a1' }).commit(),
  );
});

function bulkBatch(db, count) {
  const batch = writeBatch(db);
  for (let i = 0; i < count; i++) {
    const auditId = `bulk-${count}-${i}`;
    batch.set(doc(db, `ports/bulk${i}`), {
      id: `bulk${i}`, updatedAt: serverTimestamp(), updatedBy: 'admin1', auditId,
    });
    batch.set(doc(db, `audit_log/${auditId}`), {
      uid: 'admin1', action: 'create', at: serverTimestamp(), collection: 'ports', docId: `bulk${i}`,
    });
  }
  return batch;
}

// Production Firestore allows 20 exists/get/getAfter calls per batch; the
// emulator does not enforce that limit, so this only checks the batch shape.
// The panel uses starterBatchSize = 4 (at most ~14 calls).
test('a batch of 4 audited documents is accepted', async () => {
  await assertSucceeds(bulkBatch(as('admin1'), 4).commit());
});

test('a write without its audit entry is refused', async () => {
  const db = as('editor1');
  await assertFails(setDoc(doc(db, 'ports/p1'), {
    name: 'x', updatedAt: serverTimestamp(), updatedBy: 'editor1', auditId: 'missing',
  }));
});

test('an audit entry for a different document does not count', async () => {
  await assertFails(
    auditedBatch(as('editor1'), 'editor1', { auditFor: { collection: 'ports', docId: 'other' } }).commit(),
  );
});

test('writes must carry server time and the real author', async () => {
  const db = as('editor1');
  const batch = writeBatch(db);
  batch.set(doc(db, 'ports/p1'), {
    name: 'x', updatedAt: new Date(), updatedBy: 'editor1', auditId: 'a2',
  });
  batch.set(doc(db, 'audit_log/a2'), {
    uid: 'editor1', action: 'update', at: serverTimestamp(), collection: 'ports', docId: 'p1',
  });
  await assertFails(batch.commit());
  await assertFails(auditedBatch(db, 'admin1').commit());
});

test('travellers and anonymous users cannot write data', async () => {
  await assertFails(auditedBatch(as('anon1'), 'anon1').commit());
  await assertFails(setDoc(doc(anon(), 'ports/p1'), { name: 'x' }));
});

test('a delete (deleted: true) needs its change-log entry, like any edit', async () => {
  const db = as('editor1');
  await assertFails(setDoc(doc(db, 'ports/p1'), {
    id: 'p1', name: 'Port 1', deleted: true,
    updatedAt: serverTimestamp(), updatedBy: 'editor1', auditId: 'no-entry',
  }));
  const batch = writeBatch(db);
  batch.set(doc(db, 'ports/p1'), {
    id: 'p1', name: 'Port 1', deleted: true,
    updatedAt: serverTimestamp(), updatedBy: 'editor1', auditId: 'del-1',
  });
  batch.set(doc(db, 'audit_log/del-1'), {
    uid: 'editor1', action: 'delete', at: serverTimestamp(), collection: 'ports', docId: 'p1',
    before: { id: 'p1', name: 'Port 1' }, after: null,
  });
  await assertSucceeds(batch.commit());
});

test('restoring is logged with the restore action', async () => {
  const db = as('admin1');
  const batch = writeBatch(db);
  batch.set(doc(db, 'ports/p1'), {
    id: 'p1', name: 'Port 1', updatedAt: serverTimestamp(), updatedBy: 'admin1', auditId: 'res-1',
  });
  batch.set(doc(db, 'audit_log/res-1'), {
    uid: 'admin1', action: 'restore', at: serverTimestamp(), collection: 'ports', docId: 'p1',
    before: null, after: { id: 'p1', name: 'Port 1' }, note: 'Restored from the change log',
  });
  await assertSucceeds(batch.commit());
});

test('travel documents are never hard-deleted', async () => {
  await assertFails(deleteDoc(doc(as('admin1'), 'ports/p1')));
});

// ---------- users ----------

test('only admins manage users', async () => {
  await assertFails(setDoc(doc(as('editor1'), 'admins/new'), { role: 'editor', email: 'n@example.com' }));
  await assertSucceeds(setDoc(doc(as('admin1'), 'admins/new'), { role: 'editor', email: 'n@example.com' }));
  await assertFails(setDoc(doc(as('admin1'), 'admins/bad'), { role: 'owner', email: 'b@example.com' }));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'admins/editor1')));
});

test('an admin cannot remove themselves', async () => {
  await assertFails(deleteDoc(doc(as('admin1'), 'admins/admin1')));
});

test('editors read only their own user record', async () => {
  await assertSucceeds(getDoc(doc(as('editor1'), 'admins/editor1')));
  await assertFails(getDoc(doc(as('editor1'), 'admins/admin1')));
  await assertFails(getDoc(doc(as('anon1'), 'admins/admin1')));
});

// ---------- audit log ----------

test('the change log cannot be edited, and only admins delete entries', async () => {
  await assertSucceeds(getDoc(doc(as('editor1'), 'audit_log/old')));
  await assertFails(getDoc(doc(as('anon1'), 'audit_log/old')));
  await assertFails(updateDoc(doc(as('admin1'), 'audit_log/old'), { docId: 'x' }));
  await assertFails(deleteDoc(doc(as('editor1'), 'audit_log/old')));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'audit_log/old')));
});

test('audit entries must name their author and use server time', async () => {
  const db = as('editor1');
  await assertFails(setDoc(doc(db, 'audit_log/x'), {
    uid: 'admin1', action: 'update', at: serverTimestamp(), collection: 'ports', docId: 'p1',
  }));
  await assertFails(setDoc(doc(db, 'audit_log/y'), {
    uid: 'editor1', action: 'update', at: new Date(), collection: 'ports', docId: 'p1',
  }));
});

// ---------- reports ----------

function report(uid, extra = {}) {
  return {
    kind: 'fareChange', targetCollection: 'ship_fares', targetId: 'v1:a-b:economy',
    targetLabel: 'A → B', suggestedValue: '₱720', note: '', language: 'en',
    status: 'pending', reporterUid: uid, appVersion: '1.0.0+1',
    submittedAt: serverTimestamp(), ...extra,
  };
}

test('an anonymous traveller can file a report in a daily slot', async () => {
  const db = as('anon1');
  await assertSucceeds(setDoc(doc(db, `reports/anon1_${DAY}_1`), report('anon1')));
  await assertSucceeds(setDoc(doc(db, `reports/anon1_${DAY}_10`), report('anon1')));
});

test('report ids must be the reporter, a nearby day and slot 1 to 10', async () => {
  const db = as('anon1');
  await assertFails(setDoc(doc(db, `reports/anon2_${DAY}_1`), report('anon1')));
  await assertFails(setDoc(doc(db, `reports/anon1_${DAY}_11`), report('anon1')));
  await assertFails(setDoc(doc(db, `reports/anon1_${DAY}_0`), report('anon1')));
  await assertFails(setDoc(doc(db, `reports/anon1_${DAY - 5}_1`), report('anon1')));
  await assertFails(setDoc(doc(db, 'reports/random'), report('anon1')));
});

test('a used slot cannot be overwritten', async () => {
  const db = as('anon1');
  await assertSucceeds(setDoc(doc(db, `reports/anon1_${DAY}_2`), report('anon1')));
  await assertFails(setDoc(doc(db, `reports/anon1_${DAY}_2`), report('anon1')));
});

test('reports are validated', async () => {
  const db = as('anon1');
  const id = `reports/anon1_${DAY}_3`;
  await assertFails(setDoc(doc(db, id), report('anon1', { suggestedValue: '', note: '' })));
  await assertFails(setDoc(doc(db, id), report('anon1', { note: 'x'.repeat(1001) })));
  await assertFails(setDoc(doc(db, id), report('anon1', { status: 'approved' })));
  await assertFails(setDoc(doc(db, id), report('anon1', { kind: 'spam' })));
  await assertFails(setDoc(doc(db, id), report('anon1', { phone: '0917' })));
  await assertFails(setDoc(doc(db, id), report('anon1', { submittedAt: new Date() })));
  await assertFails(setDoc(doc(anon(), id), report('anon1')));
});

test('reporters see only their own reports', async () => {
  await assertSucceeds(getDoc(doc(as('anon1'), 'reports/existing_1_1')));
  await assertFails(getDoc(doc(as('anon2'), 'reports/existing_1_1')));
  await assertSucceeds(getDocs(query(collection(as('anon1'), 'reports'), where('reporterUid', '==', 'anon1'))));
  await assertFails(getDocs(collection(as('anon1'), 'reports')));
});

test('staff review reports but cannot rewrite them', async () => {
  const db = as('editor1');
  const r = doc(db, 'reports/existing_1_1');
  await assertSucceeds(getDoc(r));
  await assertSucceeds(updateDoc(r, {
    status: 'rejected', rejectReason: 'Duplicate', reviewedBy: 'editor1', reviewedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(r, {
    note: 'changed', status: 'approved', reviewedBy: 'editor1', reviewedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(as('anon1'), 'reports/existing_1_1'), {
    status: 'approved', reviewedBy: 'anon1', reviewedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(r));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'reports/existing_1_1')));
});

// ---------- storage ----------

const jpeg = (size) => new Uint8Array(size);

test('staff upload guide photos; anyone views them', async () => {
  const staff = env.authenticatedContext('editor1').storage();
  await assertSucceeds(uploadBytes(ref(staff, 'guides/g1/a.jpg'), jpeg(1000), { contentType: 'image/jpeg' }));
  await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), 'guides/g1/a.jpg')));
});

test('photo uploads are limited to staff, images and 1 MB', async () => {
  const traveller = env.authenticatedContext('anon1').storage();
  await assertFails(uploadBytes(ref(traveller, 'guides/g1/b.jpg'), jpeg(1000), { contentType: 'image/jpeg' }));
  const staff = env.authenticatedContext('editor1').storage();
  await assertFails(uploadBytes(ref(staff, 'guides/g1/big.jpg'), jpeg(1024 * 1024 + 1), { contentType: 'image/jpeg' }));
  await assertFails(uploadBytes(ref(staff, 'guides/g1/notes.txt'), jpeg(10), { contentType: 'text/plain' }));
  await assertFails(uploadBytes(ref(staff, 'other/x.jpg'), jpeg(10), { contentType: 'image/jpeg' }));
});
