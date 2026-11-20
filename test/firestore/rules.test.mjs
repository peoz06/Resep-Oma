import { readFile } from 'node:fs/promises';
import { before, after, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, onSnapshot, query, serverTimestamp, setDoc, updateDoc, where, writeBatch } from 'firebase/firestore';
import assert from 'node:assert/strict';

// Project demo dan host emulator wajib: tes ini tidak boleh menyentuh cloud.
assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Jalankan melalui firebase emulators:exec');
let env;
const recipe = (authorId = 'owner') => ({
  title: 'Sup Ayam', authorId, authorName: authorId, authorAvatar: '',
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
    name: 'newUser', email: 'baru@example.com', role: 'user', status: 'active', pending: false,
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

test('Suka memerlukan transaksi penghitung; tamu dan akun lain tidak dapat memalsukan', async () => {
  const db = signedIn('other');
  await assertFails(updateDoc(at(db, 'recipes/recipe1'), { likesCount: 4 }));
  await assertFails(setDoc(at(db, 'likes/other__recipe1'), {
    uid: 'other', recipeId: 'recipe1', createdAt: serverTimestamp(),
  }));
  const batch = writeBatch(db);
  batch.update(at(db, 'recipes/recipe1'), { likesCount: 4 });
  batch.set(at(db, 'likes/other__recipe1'), {
    uid: 'other', recipeId: 'recipe1', createdAt: serverTimestamp(),
  });
  batch.set(at(db, 'notifications/like-other__recipe1'), {
    recipientId: 'owner', actorId: 'other', recipeId: 'recipe1',
    kind: 'like', title: 'Sup Ayam', seen: false, createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(at(db, 'recipes/recipe1'))).data().likesCount, 4);
  await assertFails(getDoc(at(signedIn('owner'), 'likes/other__recipe1')));
  await assertSucceeds(getDoc(at(signedIn('owner'), 'notifications/like-other__recipe1')));
  await assertFails(getDoc(at(signedIn('admin'), 'notifications/like-other__recipe1')));
  await assertFails(updateDoc(at(db, 'notifications/like-other__recipe1'), { seen: true }));
  await assertSucceeds(updateDoc(at(signedIn('owner'), 'notifications/like-other__recipe1'), { seen: true }));
  const undo = writeBatch(db);
  undo.update(at(db, 'recipes/recipe1'), { likesCount: 3 });
  undo.delete(at(db, 'likes/other__recipe1'));
  await assertSucceeds(undo.commit());
});

test('Recook hanya sekali per akun dan angka tidak bisa dinaikkan sendiri', async () => {
  const db = signedIn('other');
  await assertFails(updateDoc(at(db, 'recipes/recipe1'), { recooksCount: 1 }));
  const batch = writeBatch(db);
  batch.update(at(db, 'recipes/recipe1'), { recooksCount: 1 });
  batch.set(at(db, 'recooks/other__recipe1'), {
    uid: 'other', recipeId: 'recipe1', createdAt: serverTimestamp(),
  });
  batch.set(at(db, 'notifications/recook-other__recipe1'), {
    recipientId: 'owner', actorId: 'other', recipeId: 'recipe1',
    kind: 'recook', title: 'Sup Ayam', seen: false, createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(at(db, 'recooks/other__recipe1'), {
    uid: 'other', recipeId: 'recipe1', createdAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(at(db, 'recooks/other__recipe1')));
});

test('Ulasan membuat notifikasi nyata untuk pemilik resep saja', async () => {
  const db = signedIn('other');
  const batch = writeBatch(db);
  batch.set(at(db, 'recipes/recipe1/comments/other__recipe1'), {
    authorId: 'other', authorName: 'other', text: 'Enak', rating: 4,
    createdAt: serverTimestamp(),
  });
  batch.set(at(db, 'notifications/comment-other__recipe1'), {
    recipientId: 'owner', actorId: 'other', recipeId: 'recipe1',
    eventId: 'other__recipe1', kind: 'comment', title: 'Sup Ayam',
    seen: false, createdAt: serverTimestamp(),
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDocs(query(collection(signedIn('owner'), 'notifications'),
    where('recipientId', '==', 'owner'))));
  await assertFails(getDocs(query(collection(signedIn('admin'), 'notifications'),
    where('recipientId', '==', 'owner'))));
  await assertFails(setDoc(at(db, 'notifications/comment-fake'), {
    recipientId: 'owner', actorId: 'other', recipeId: 'recipe1',
    eventId: 'fake', kind: 'comment', title: 'Sup Ayam',
    seen: false, createdAt: serverTimestamp(),
  }));
});

test('Ulasan & rating publik, identitas penulis dan nilai tidak bisa dipalsukan', async () => {
  const path = 'recipes/recipe1/comments/other__recipe1';
  await assertSucceeds(setDoc(at(signedIn('other'), path), {
    authorId: 'other', authorName: 'other', text: 'Enak', rating: 5,
    createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDocs(collection(guest(), 'recipes/recipe1/comments')));
  await assertSucceeds(updateDoc(at(signedIn('other'), path), { text: 'Lebih enak', rating: 4 }));
  await assertFails(setDoc(at(signedIn('other'), 'recipes/recipe1/comments/spam'), {
    authorId: 'other', authorName: 'other', text: 'Spam', rating: 5,
    createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(at(signedIn('owner'), path), { rating: 1 }));
  await assertFails(updateDoc(at(signedIn('other'), path), { authorId: 'owner' }));
  await assertFails(setDoc(at(signedIn('owner'), 'recipes/recipe1/comments/owner__recipe1'), {
    authorId: 'other', authorName: 'Palsu', text: 'Spam', rating: 9,
    createdAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(at(guest(), path)));
  await assertSucceeds(deleteDoc(at(signedIn('other'), path)));
});

test('Ikuti hanya akun aktif; hitungan pengikut dapat dibaca pemilik akun', async () => {
  const db = signedIn('other');
  const path = 'follows/other__owner';
  await assertSucceeds(setDoc(at(db, path), {
    followerId: 'other', followingId: 'owner', createdAt: serverTimestamp(),
  }));
  await assertSucceeds(getDocs(query(collection(signedIn('owner'), 'follows'),
    where('followingId', '==', 'owner'))));
  await assertFails(getDoc(at(signedIn('admin'), path)));
  await assertFails(setDoc(at(signedIn('banned'), 'follows/banned__owner'), {
    followerId: 'banned', followingId: 'owner', createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(at(db, 'follows/other__other'), {
    followerId: 'other', followingId: 'other', createdAt: serverTimestamp(),
  }));
  await assertSucceeds(deleteDoc(at(db, path)));
});

test('Draf hanya dapat dibaca dan diedit pemilik aktif', async () => {
  const data = {
    uid: 'owner', title: 'Sup belum selesai', description: '', category: '',
    cookTime: '', servings: '', difficulty: '', ingredients: [], steps: [],
    updatedAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(at(signedIn('owner'), 'drafts/owner'), data));
  await assertSucceeds(getDoc(at(signedIn('owner'), 'drafts/owner')));
  await assertFails(getDoc(at(signedIn('other'), 'drafts/owner')));
  await assertFails(getDoc(at(guest(), 'drafts/owner')));
  await assertFails(setDoc(at(signedIn('suspended'), 'drafts/suspended'), { ...data, uid: 'suspended' }));
  await assertFails(setDoc(at(signedIn('owner'), 'drafts/owner'), { ...data, image: 'file:///private/photo' }));
  await assertSucceeds(deleteDoc(at(signedIn('owner'), 'drafts/owner')));
});

test('Nama penulis resep/ulasan tidak bisa dipalsukan; profil baru dapat disinkronkan', async () => {
  const db = signedIn('owner');
  await assertFails(setDoc(at(db, 'recipes/fakeAuthor'), {
    ...recipe('owner'), authorName: 'Admin Palsu',
  }));
  await assertFails(setDoc(at(db, 'recipes/recipe1/comments/owner__recipe1'), {
    authorId: 'owner', authorName: 'Admin Palsu', text: 'Hebat', rating: 5,
    createdAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(at(db, 'recipes/recipe1'), { authorName: 'Admin Palsu' }));
  await assertSucceeds(updateDoc(at(db, 'users/owner'), { name: 'Oma Baru' }));
  await assertSucceeds(updateDoc(at(db, 'recipes/recipe1'), {
    authorName: 'Oma Baru', authorAvatar: null, updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(at(db, 'recipes/recipe1'), { authorName: 'Admin Palsu' }));
});

test('Hanya admin aktif dapat mengubah role orang lain dan verifikasi resep', async () => {
  await assertFails(updateDoc(at(signedIn('owner'), 'users/other'), { role: 'admin' }));
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'users/other'), { role: 'creator' }));
  await assertFails(updateDoc(at(signedIn('owner'), 'recipes/recipe1'), { verified: true }));
  await assertSucceeds(updateDoc(at(signedIn('admin'), 'recipes/recipe1'), { verified: true }));
  await assertFails(updateDoc(at(signedIn('suspendedAdmin'), 'recipes/recipe1'), { verified: false }));
});
