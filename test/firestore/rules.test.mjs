import { readFile } from 'node:fs/promises';
import { before, after, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, onSnapshot, query, setDoc, updateDoc, where } from 'firebase/firestore';
import assert from 'node:assert/strict';

// Project demo dan host emulator wajib: tes ini tidak boleh menyentuh cloud.
assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Jalankan melalui firebase emulators:exec');
let env;
const recipe = (authorId = 'owner') => ({
  title: 'Sup Ayam', authorId, authorName: 'Koki Publik', authorAvatar: '',
  image: 'https://example.com/sup.jpg', ingredients: [{ name: 'Ayam', amount: '500 g' }],
  steps: [{ title: 'Rebus', description: 'Rebus hingga matang.' }], likesCount: 3,
});
const signedIn = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'password' } }).firestore();
const guest = () => env.unauthenticatedContext().firestore();
const at = (db, path) => doc(db, path);

before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-resep-oma',
    firestore: { host, port: Number(port), rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [uid, role, status] of [
      ['admin', 'admin', 'active'], ['owner', 'user', 'active'],
      ['other', 'user', 'active'], ['suspended', 'user', 'suspended'],
      ['banned', 'user', 'banned'], ['legacy', 'user', undefined],
      ['nullStatus', 'user', null], ['unknownStatus', 'user', 'unknown'],
      ['suspendedAdmin', 'admin', 'suspended'],
    ]) {
      await setDoc(at(db, `users/${uid}`), { name: uid, role, ...(status !== undefined ? { status } : {}) });
    }
    await setDoc(at(db, 'recipes/recipe1'), recipe());
    await setDoc(at(db, 'favorites/owner__recipe1'), { uid: 'owner', recipeId: 'recipe1' });
    await setDoc(at(db, 'reports/report1'), { reporterId: 'owner', recipeId: 'recipe1', reason: 'Foto salah', status: 'open' });
  });
});

test('Admin menghapus resep orang lain: berhasil', async () => {
  await assertSucceeds(deleteDoc(at(signedIn('admin'), 'recipes/recipe1')));
});
test('User biasa menghapus resep orang lain: ditolak', async () => {
  await assertFails(deleteDoc(at(signedIn('other'), 'recipes/recipe1')));
});
test('Pemilik aktif mengubah dan menghapus resep sendiri: berhasil', async () => {
  const ref = at(signedIn('owner'), 'recipes/recipe1');
  await assertSucceeds(updateDoc(ref, { title: 'Sup Baru' }));
  await assertSucceeds(deleteDoc(ref));
});
test('User suspended/banned/status tidak valid membuat resep: ditolak', async () => {
  for (const uid of ['suspended', 'banned', 'nullStatus', 'unknownStatus']) {
    await assertFails(setDoc(at(signedIn(uid), `recipes/${uid}`), recipe(uid)));
  }
});
test('Suspended tidak bisa mengedit/menghapus resep sendiri; admin suspended juga ditolak', async () => {
  await env.withSecurityRulesDisabled((context) => setDoc(at(context.firestore(), 'recipes/blocked'), recipe('suspended')));
  await assertFails(updateDoc(at(signedIn('suspended'), 'recipes/blocked'), { title: 'Ubah' }));
  await assertFails(deleteDoc(at(signedIn('suspended'), 'recipes/blocked')));
  await assertFails(deleteDoc(at(signedIn('suspendedAdmin'), 'recipes/recipe1')));
});
test('User mengubah role/status sendiri: ditolak', async () => {
  await assertFails(updateDoc(at(signedIn('owner'), 'users/owner'), { role: 'admin' }));
  await assertFails(updateDoc(at(signedIn('banned'), 'users/banned'), { status: 'active' }));
});
test('Registrasi profil akun baru: berhasil', async () => {
  await assertSucceeds(setDoc(at(signedIn('newUser'), 'users/newUser'), {
    name: 'Baru', email: 'baru@example.com', role: 'user', status: 'active', pending: false,
  }));
  await assertSucceeds(setDoc(at(signedIn('newUser'), 'recipes/new'), recipe('newUser')));
});
test('Registrasi dengan role admin atau UID orang lain: ditolak', async () => {
  await assertFails(setDoc(at(signedIn('newUser'), 'users/newUser'), { role: 'admin', status: 'active' }));
  await assertFails(setDoc(at(signedIn('newUser'), 'users/someoneElse'), { role: 'user', status: 'active' }));
});
test('Tamu unauthenticated membaca resep/detail/katalog: berhasil', async () => {
  await assertSucceeds(getDoc(at(guest(), 'recipes/recipe1')));
  await assertSucceeds(getDocs(collection(guest(), 'recipes')));
});
test('Tamu membaca users, favorites, reports: ditolak', async () => {
  for (const path of ['users/owner', 'favorites/owner__recipe1', 'reports/report1']) {
    await assertFails(getDoc(at(guest(), path)));
  }
});
test('Tamu membuat resep/favorit/laporan/profil: ditolak', async () => {
  await assertFails(setDoc(at(guest(), 'recipes/new'), recipe()));
  await assertFails(setDoc(at(guest(), 'favorites/owner__new'), { uid: 'owner', recipeId: 'new' }));
  await assertFails(setDoc(at(guest(), 'reports/new'), { reporterId: 'owner', reason: 'Spam', status: 'open' }));
  await assertFails(setDoc(at(guest(), 'users/owner'), { role: 'user', status: 'active' }));
});
test('Sesi Firebase anonymous hanya dapat membaca resep', async () => {
  const db = env.authenticatedContext('anonymous', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
  await assertSucceeds(getDoc(at(db, 'recipes/recipe1')));
  await assertFails(getDoc(at(db, 'users/owner')));
  await assertFails(setDoc(at(db, 'users/anonymous'), { role: 'user', status: 'active' }));
  await assertFails(setDoc(at(db, 'recipes/new'), recipe('anonymous')));
  await assertFails(setDoc(at(db, 'favorites/anonymous__new'), { uid: 'anonymous', recipeId: 'new' }));
});
test('Akun login tanpa dokumen user membuat resep: ditolak', async () => {
  await assertFails(setDoc(at(signedIn('noProfile'), 'recipes/new'), recipe('noProfile')));
});
test('User aktif tidak bisa memalsukan authorId', async () => {
  await assertFails(setDoc(at(signedIn('owner'), 'recipes/new'), recipe('other')));
  await assertFails(updateDoc(at(signedIn('owner'), 'recipes/recipe1'), { authorId: 'other' }));
});
test('Akun lama tanpa status dianggap aktif tetapi tidak boleh mengubah role/status sendiri', async () => {
  await assertSucceeds(setDoc(at(signedIn('legacy'), 'recipes/new'), recipe('legacy')));
  await assertSucceeds(updateDoc(at(signedIn('legacy'), 'users/legacy'), { name: 'Nama Baru' }));
  await assertFails(updateDoc(at(signedIn('legacy'), 'users/legacy'), { status: 'active' }));
  await assertFails(updateDoc(at(signedIn('legacy'), 'users/legacy'), { role: 'admin' }));
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'users/legacy'), { status: 'active' }));
});
test('Admin mengubah/menghapus resep orang lain, user tidak bisa menambah field email', async () => {
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'recipes/recipe1'), { title: 'Dimoderasi' }));
  await assertFails(updateDoc(at(signedIn('owner'), 'recipes/recipe1'), { email: 'privat@example.com' }));
  await assertFails(setDoc(at(signedIn('owner'), 'recipes/private'), { ...recipe(), authorEmail: 'privat@example.com' }));
});
test('User tidak membaca profil orang lain; admin membaca daftar, tanpa delete profil', async () => {
  await assertSucceeds(getDoc(at(signedIn('owner'), 'users/owner')));
  await assertFails(getDoc(at(signedIn('other'), 'users/owner')));
  await assertSucceeds(getDocs(collection(signedIn('admin'), 'users')));
  await assertFails(deleteDoc(at(signedIn('admin'), 'users/owner')));
});
test('Admin memblokir pengguna tanpa menghapus dokumen; akun tidak dapat membuka blokir sendiri', async () => {
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'users/owner'), { status: 'banned' }));
  assert.equal((await getDoc(at(signedIn('admin'), 'users/owner'))).data().status, 'banned');
  await assertFails(updateDoc(at(signedIn('owner'), 'users/owner'), { status: 'active' }));
  await assertFails(setDoc(at(signedIn('owner'), 'recipes/new'), recipe()));
  await assertFails(updateDoc(at(signedIn('admin'), 'users/admin'), { status: 'banned' }));
});
test('Listener profil menerima perubahan suspended dan banned', async () => {
  const ref = at(signedIn('owner'), 'users/owner');
  const received = [];
  let stop;
  const changes = new Promise((resolve, reject) => {
    stop = onSnapshot(ref, (snapshot) => {
      const status = snapshot.data().status;
      received.push(status);
      if (status === 'active') updateDoc(at(signedIn('admin'), 'users/owner'), { status: 'suspended' }).catch(reject);
      if (status === 'suspended') updateDoc(at(signedIn('admin'), 'users/owner'), { status: 'banned' }).catch(reject);
      if (status === 'banned') resolve();
    }, reject);
  });
  try {
    await Promise.race([changes, new Promise((_, reject) => setTimeout(() => reject(new Error('Listener timeout')), 10000).unref())]);
    assert.ok(received.includes('suspended') && received.includes('banned'));
  } finally { stop?.(); }
});
test('Favorit hanya milik sendiri: get baru, query, create/update/delete', async () => {
  const db = signedIn('owner');
  const ref = at(db, 'favorites/owner__new');
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(setDoc(ref, { uid: 'owner', recipeId: 'new' }));
  await assertSucceeds(updateDoc(ref, { createdAt: new Date() }));
  await assertSucceeds(getDocs(query(collection(db, 'favorites'), where('uid', '==', 'owner'))));
  await assertFails(getDoc(at(signedIn('other'), 'favorites/owner__new')));
  await assertFails(getDoc(at(signedIn('admin'), 'favorites/owner__new')));
  await assertFails(updateDoc(ref, { uid: 'other' }));
  await assertFails(deleteDoc(at(signedIn('other'), 'favorites/owner__new')));
  await assertSucceeds(deleteDoc(ref));
});
test('Laporan: user membuat, hanya admin membaca/mengubah/menghapus', async () => {
  await assertSucceeds(setDoc(at(signedIn('owner'), 'reports/new'), { reporterId: 'owner', reason: 'Spam', status: 'open' }));
  await assertFails(getDoc(at(signedIn('owner'), 'reports/new')));
  await assertFails(updateDoc(at(signedIn('owner'), 'reports/new'), { status: 'resolved' }));
  await assertSucceeds(getDocs(collection(signedIn('admin'), 'reports')));
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'reports/new'), { status: 'resolved' }));
  await assertSucceeds(deleteDoc(at(signedIn('admin'), 'reports/new')));
});
test('Koleksi dan subkoleksi lain ditolak tanpa wildcard permisif', async () => {
  for (const db of [guest(), signedIn('owner'), signedIn('admin')]) {
    await assertFails(setDoc(at(db, 'unknown/doc'), { value: 1 }));
    await assertFails(getDoc(at(db, 'unknown/doc')));
    await assertFails(getDoc(at(db, 'recipes/recipe1/private/doc')));
  }
});
