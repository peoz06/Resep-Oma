# Moderasi Firebase tanpa Cloud Functions

Perubahan moderasi berlaku pada Flutter (`lib/`). Prototipe React (`src/`) tidak
mengakses Firestore. Tidak menggunakan Cloud Functions. Pemilik project telah
memublikasikan rules terbaru di Console; akses baca resep tanpa login dan
penolakan baca profil tanpa login telah diuji. Agent tidak melakukan deploy.

## Koleksi, field, dan izin

| Koleksi | Field aplikasi |
|---|---|
| `users/{uid}` | `name`, `email`, `role`, `status`, `avatar`, `provider`, `code`, `pending`, `createdAt`, `updatedAt` |
| `recipes/{id}` | `code`, `title`, `description`, `category`, `filterKey`, `cookTime`, `servings`, `difficulty`, `image`, `images`, `authorId`, `authorName`, `authorAvatar`, `likesCount`, `recooksCount`, `reportedCount`, `verified`, `status`, `ingredients[{name,amount}]`, `steps[{title,description}]`, `createdAt`, `updatedAt` |
| `favorites/{uid__recipeId}` | `uid`, `recipeId`, `createdAt` |
| `reports/{id}` | `recipeId`, `recipeTitle`, `reporterId`, `reporterName`, `reason`, `status`, `createdAt`, `resolvedAt` |
| `likes/{uid__recipeId}` & `recooks/{uid__recipeId}` | `uid`, `recipeId`, `createdAt` (angka pada resep ditulis bersamaan dalam transaksi) |
| `follows/{uid__followingId}` | `followerId`, `followingId`, `createdAt` |
| `recipes/{id}/comments/{uid__recipeId}` | `authorId`, `authorName`, `text`, `rating`, `createdAt` |
| `notifications/{id}` | `recipientId`, `actorId`, `recipeId`, `kind`, `title`, `seen`, `createdAt` |
| `drafts/{uid}` | teks/form draf, tanpa foto lokal |

| Koleksi | Tamu / Firebase Anonymous | Pengguna login | Admin aktif |
|---|---|---|---|
| `recipes` | read | create dengan authorId sendiri; update/delete milik sendiri jika aktif | create sendiri; read/update/delete semua |
| `users` | ditolak | read sendiri; create sendiri sebagai user/active; update nama/email/avatar sendiri jika aktif | read semua; update pengguna lain termasuk role/status; create catatan pending; tanpa delete |
| `favorites` | ditolak | read/create/update/delete sendiri | hanya milik sendiri |
| `likes`, `recooks` | ditolak | read milik sendiri; suka bisa dibatalkan, recook sekali per resep | sama seperti pengguna; tidak bisa menambah angka sembarang |
| `follows` | ditolak | ikuti akun aktif; lihat hubungan sendiri dan jumlah pengikut sendiri | sama seperti pengguna |
| `comments` | read pada resep yang ada | tulis/ubah/hapus ulasan sendiri | read semua; hapus ulasan bermasalah |
| `notifications` | ditolak | baca notifikasi sendiri; aktivitas valid dibuat bersama aksi resep | sama seperti pengguna |
| `drafts` | ditolak | baca/tulis/hapus draf sendiri | sama seperti pengguna |
| `reports` | ditolak | pengguna aktif membuat laporan dengan identitas sendiri | read/update/delete semua; create dengan identitas sendiri |
| lainnya/subkoleksi | ditolak | ditolak | ditolak |

Resep baru wajib memakai `verified:false`, `likesCount:0`, dan `recooksCount:0`.
Verifikasi berikutnya hanya melalui admin; suka/recook melalui transaksi terkait.
Notifikasi dibatasi 30 terbaru (penanda Beranda: satu yang belum dibaca), ulasan
20 terbaru dengan rata-rata dari kumpulan tersebut. Jumlah pengikut memakai
agregasi `count()` di server, bukan mengunduh seluruh dokumen hubungan.

`read` mencakup get dan query. Koleksi yang
tidak disebut ditolak secara default, tanpa `match /{document=**}`.
Profil hanya dibaca pemilik/admin karena berisi email. Admin harus memiliki
dokumen `users/{uid}` sendiri dengan `role:admin` dan status aktif.

## Status dan sesi

- `active`: boleh masuk dan menulis resep sendiri.
- `suspended` / `banned`: login aplikasi ditolak; sesi aktif dikeluarkan dengan
  pesan. Ban mempertahankan dokumen pengguna dan label **Diblokir**.
- `baru`: hanya catatan pending admin, bukan akun aktif.
- Dokumen lama **tanpa field status** dianggap active oleh Flutter dan rules.
  Nilai null/tidak dikenal tidak aktif. Dokumen user yang hilang tidak memberi
  izin membuat resep.
- User tidak boleh menambah, mengubah, atau menghapus role/status sendiri.
  Admin dapat menambahkan status pada profil lama melalui Console atau mengubah
  status pengguna lain lewat aplikasi.

Login email/password, Google, dan pemulihan sesi memakai pemeriksaan status yang
sama. Profil dibaca dari server; kegagalan pembacaan tidak menjadi profil aktif
fallback. Login pertama membuat profil user/active bila dokumennya belum ada.
Listener profil mengeluarkan sesi jika akun nonaktif atau profil hilang;
listener dibatalkan saat logout/dispose. Pencabutan role menutup panel admin.

Tanpa Admin SDK/Console, aplikasi tidak menonaktifkan akun Firebase Auth atau
mencabut semua token. Firebase Auth mungkin menerbitkan token setelah kredensial
valid; aplikasi kemudian memeriksa profil dan sign out. Rules menolak penulisan
resep nonaktif meskipun token masih ada. Resep tetap publik; favorit/laporan
mengikuti izin login pada tabel, bukan pencabutan token global.

Profil pending buatan admin hanya catatan, bukan akun Authentication. Registrasi
tidak lagi mencari/menghapus profil orang lain berdasarkan email. Moderasi login
harus menyasar dokumen dengan ID **UID Auth akun sebenarnya**, bukan ID pending.

## Privasi dan penghapusan

Resep sudah menyimpan `authorName` dan `authorAvatar`; layar resep tidak membaca
`users` untuk nama/foto penulis. Payload resep tidak menyalin email atau profil
privat. Perubahan nama/foto profil menyelaraskan resep lama milik pengguna.
Rules membatasi field tingkat atas; `email`/`authorEmail` ditolak.

**Sebelum membuka read publik, periksa data resep lama di cloud.** Rules tidak
menyensor field yang sudah ada, teks bebas, isi nested, atau URL berisi data
pribadi. Jangan masukkan data pribadi ke judul/deskripsi/bahan/langkah/URL.
Dokumen lama dengan field tambahan perlu dibersihkan agar update lolos whitelist.

Hapus resep hanya menghapus dokumen resep dan memperbarui daftar aplikasi.
Laporan dipertahankan sebagai riwayat. Favorit yang menunjuk resep hilang tidak
ditampilkan; client tidak menghapus favorit pengguna lain. File foto tidak dihapus.

Supabase tetap memakai upload anon sesuai konfigurasi sebelumnya. Rules Firestore
tidak mengamankan API upload Supabase: akun banned masih dapat memanggil upload
langsung jika policy Supabase mengizinkannya, tetapi tidak dapat menyimpan resep.

## Deploy rules terbaru dan pemeriksaan admin/data

Pemilik telah memublikasikan rules terbaru. Periksa data/role dan aturan
produksi lainnya sebelum mencoba fitur baru.

1. Tinjau semua role admin lama. Rules live sebelumnya memungkinkan pengguna
   menulis role sendiri; role yang tersimpan belum tentu tepercaya.
2. Siapkan admin awal melalui Console tepercaya: `users/<UID Auth>` dengan
   `role:admin,status:active`. Client tidak dapat menaikkan role sendiri.
3. Periksa privasi dan field dokumen resep lama.
4. Jalankan tes emulator dan uji aplikasi dua sesi di bawah.
5. Untuk perubahan rules berikutnya, ganti **seluruh** rules live melalui Console
   setelah pengujian. Jangan sisakan match permisif lama. Agent tidak melakukan deploy.
6. Perbaikan audit ini belum dipublikasikan otomatis. Deploy `firestore.rules` dan
   `firestore.indexes.json` melalui
   `firebase deploy --only firestore:rules,firestore:indexes --project resep-oma`,
   atau buat indeks notifikasi di Console (`recipientId` ascending,
   `createdAt` descending). Tunggu indeks siap sebelum menguji daftar notifikasi.

## Emulator: tes rules otomatis

Prasyarat: Node 20+ dan Java 21+ untuk Firebase CLI 15. Dari root repository:

```bash
npm --prefix test/firestore ci
firebase emulators:exec --only firestore --project demo-resep-oma "npm --prefix test/firestore test"
```

Project demo terisolasi. Tes mewajibkan `FIRESTORE_EMULATOR_HOST` dan memakai
rules lokal. Fixture disiapkan tanpa rules hanya selama seeding; operasi yang
diuji tetap melalui rules. File tes: `test/firestore/rules.test.mjs`.

| Skenario wajib | Hasil yang diharapkan |
|---|---|
| Admin hapus resep orang lain | berhasil |
| User biasa hapus resep orang lain | ditolak |
| User suspended membuat resep | ditolak |
| User mengubah role sendiri | ditolak |
| Registrasi: create profil user/active | berhasil |
| Tamu Unauthenticated membaca resep | berhasil |
| Tamu membaca users | ditolak |
| Tamu membuat resep atau favorit | ditolak |
| Akun login tanpa dokumen user membuat resep | ditolak |

Tes tambahan mencakup banned, status legacy/null/tidak dikenal, anonymous, kepemilikan favorit,
laporan, pemalsuan authorId, field email, admin nonaktif, larangan delete profil,
default-deny, dan penerimaan perubahan status melalui listener SDK Firestore.

**Hasil terverifikasi:** 32 tes rules lulus pada emulator lokal. Tes emulator registrasi
hanya membuktikan create profil Firestore, bukan Firebase Authentication
end-to-end. Tes listener Node membuktikan penerimaan status, bukan logout UI Flutter.

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Hasil lokal: `flutter analyze --no-pub` tanpa temuan; 31 tes Flutter lulus.
`git diff --check` bersih. Pemeriksaan layout dilakukan lewat widget test, bukan
inspeksi visual perangkat nyata.

## Rules Playground

Gunakan project uji; Playground memakai dokumen project yang dipilih. Jangan
mengubah akun nyata untuk menyiapkan fixture. Emulator lebih aman.

1. Siapkan `users/admin` (admin/active), `users/owner` (user/active), dan
   `users/suspended` (user/suspended).
2. Siapkan `recipes/recipe1` dengan `authorId:owner`, `authorName` sesuai nama profil,
   `title:Sup`, `image:https://example.com/sup.jpg`, `ingredients:[]`, `steps:[]`,
   `verified:false`, `likesCount:0`, `recooksCount:0`.
3. DELETE `/recipes/recipe1`: UID admin allow, UID user lain deny.
4. UPDATE `/users/owner`: UID owner mengubah role menjadi admin deny.
5. CREATE resep memakai payload langkah 2 dengan authorId sesuai UID:
   UID suspended deny; UID login tanpa profil deny.
6. CREATE `/users/newUser`: UID newUser, data `name:Baru,role:user,status:active`
   allow. Ini simulasi profil setelah Auth, bukan registrasi Auth.
7. Matikan Authentication: GET resep allow; GET users deny; CREATE resep deny;
   CREATE `/favorites/owner__recipe1` berisi `uid:owner,recipeId:recipe1` deny.

Playground tidak menguji login, navigasi, atau listener Flutter.

## Uji aplikasi dua sesi sebelum menyatakan moderasi live berfungsi

1. Sesi A admin; sesi B user email/password.
2. Tangguhkan B: sesi B harus keluar dari upload/detail yang terbuka dan menerima
   pesan. Login ulang ditolak.
3. Aktifkan lagi; ulangi dengan banned. Dokumen pengguna harus tetap ada.
4. Ulangi login dan perubahan status dengan akun Google.
5. Admin hapus resep B: daftar admin dan Beranda harus diperbarui.
6. Sebagai tamu, baca katalog/detail; favorit/upload harus meminta login tanpa
   error permission-denied mentah atau lookup profil penulis.
7. Cabut role admin kedua lewat Console; panel adminnya harus tertutup.

Belum diverifikasi langsung oleh agent: login email/Google nyata, logout otomatis
Flutter dua sesi, data cloud lama, dan seluruh isi rules produksi. Rules terbaru
telah dipublikasikan menurut pemilik project.
