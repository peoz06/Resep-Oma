# Resep Oma

Aplikasi Flutter komunitas resep. Firebase Auth menangani login, Firestore
menyimpan profil/resep/URL gambar, dan Supabase Storage menyimpan file avatar
pengguna/admin serta foto resep. Folder `src/` adalah prototipe React terpisah.

## Cara menjalankan

1. Pasang Flutter dan gunakan konfigurasi Firebase project tim untuk platform
   yang dituju. Ambil dependency:

   ```bash
   flutter pub get
   ```

2. Salin konfigurasi contoh menjadi konfigurasi lokal:

   ```bash
   cp supabase.example.json supabase.local.json
   ```

   Di PowerShell, gunakan `Copy-Item supabase.example.json supabase.local.json`.
   Isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` dengan nilai project tim.
   Jangan gunakan kunci rahasia server. `supabase.local.json` di-ignore dan tidak
   boleh di-commit. Publishable key memang dapat dibaca dari aplikasi hasil build.

3. Jalankan aplikasi:

   ```bash
   flutter run --dart-define-from-file=supabase.local.json
   ```

   Untuk web, tambahkan `-d chrome`. Konfigurasi dibaca saat kompilasi;
   perubahan nilainya memerlukan aplikasi dihentikan dan dijalankan ulang.

## Rilis Android

Siapkan [keystore rilis Flutter](https://docs.flutter.dev/deployment/android#sign-the-app).
Salin `android/key.properties.example` ke `android/key.properties`, lalu isi
lokasi keystore dan kredensialnya. Path relatif dihitung dari folder `android/`.
Simpan keystore dan `key.properties` di luar Git. Build debug tidak memerlukan
konfigurasi ini; build release tidak lagi memakai kunci debug.

```bash
flutter build appbundle --release --dart-define-from-file=supabase.local.json
```

Untuk Google Sign-In, daftarkan SHA-1 sertifikat yang menandatangani APK yang
diterima pengguna. Untuk distribusi lewat Play, gunakan sertifikat Play App Signing.

Panduan lanjutan:
- [Konfigurasi bucket, upload, dan batas Supabase](SUPABASE_STORAGE.md)
- [Moderasi, aturan akses, dan tes Firestore](MODERASI_FIREBASE.md)
- [Konfigurasi Firebase per platform](FIREBASE_MIGRATION_GUIDE.md)

## Fitur aplikasi Flutter

- Resep publik: cari/filter, unggah/edit/hapus, galeri, draf teks (satu per akun;
  foto harus dipilih ulang), favorit, suka dan recook sekali per akun.
  Katalog memuat 25 resep per halaman; pencarian dan pengurutan Eksplor memakai
  resep yang sudah dimuat. Favorit dan Resep Saya dibaca terpisah dari katalog.
- Pencocokan resep dari bahan kulkas, tanpa model AI. Form terbit mendukung
  maksimal 12 bahan dan 12 langkah.
- Ulasan dan rating 1–5, ikuti koki, salin ringkasan resep untuk dibagikan,
  notifikasi aktivitas (suka/recook/ulasan) dalam aplikasi.
  Detail menampilkan maksimal 20 ulasan terbaru; rata-rata bukan dari seluruh
  ulasan. Notifikasi menampilkan maksimal 30 aktivitas terbaru; penanda di Beranda
  hanya membaca satu aktivitas yang belum dibaca.
- Admin: laporan, status dan role pengguna, serta verifikasi resep. Admin
  pertama tetap dibuat lewat Firebase Console. Pengguna dan laporan dimuat
  per 25 dokumen; pencarian pengguna dan filter Dilaporkan memakai data yang
  sudah dimuat. Total akun dan laporan terbuka dihitung oleh Firestore.
- Daftar/login, pemulihan sandi, email verifikasi, profil, tema gelap, mode tamu.

Pemilik project pernah menguji baca resep tanpa login pada project nyata.
Untuk memeriksa aturan yang ada di repo ini, jalankan tes emulator berikut:

```bash
firebase emulators:exec --only firestore --project demo-resep-oma "npm --prefix test/firestore test"
```

Firebase CLI terbaru memerlukan Java 21 untuk emulator.

## Firestore dan akun admin

Commit atau pull tidak memublikasikan rules. Sebelum meluncurkan perbaikan audit,
periksa resep lama dan isi `createdAt` yang hilang atau bukan `Timestamp` dengan
waktu terbit yang benar. Query katalog melewati dokumen tanpa field ini. Tinjau
dan publikasikan `firestore.rules` serta `firestore.indexes.json` dengan
`firebase deploy --only firestore:rules,firestore:indexes --project resep-oma`,
atau buat indeks `notifications` (`recipientId` ascending, `createdAt` descending)
di Console setelah memublikasikan rules. Tunggu indeks siap, lalu uji dengan
build Android baru. Laporan dari build lama memakai ID yang tidak lagi diterima.
Publikasikan rules terbaru sebelum menguji simpan draf di build baru. Rules ini
menerima draf lama dan field `revision` yang dipakai build baru.

Untuk upload foto, aktifkan integrasi Firebase di Supabase dan terapkan migrasi
Storage sesuai [panduan bucket](SUPABASE_STORAGE.md). Build lama yang memakai
upload anonim tidak bisa mengunggah setelah policy baru aktif.

Akun admin pertama harus diatur manual di **Firestore Console**. Setelah akun
terdaftar melalui Firebase Auth, gunakan dokumen `users/<UID Auth>` dengan
`role:admin` dan `status:active`. Jangan memakai ID catatan pending untuk admin
login. Registrasi client tidak dapat menaikkan role sendiri.

## Setelah pull dan pemeriksaan lokal

- Jalankan kembali `flutter pub get` jika dependency berubah.
- `.dart_tool/` dan `.flutter-plugins-dependencies` sengaja dikeluarkan dari
  tracking Git. Flutter membuat ulang metadata lokal tersebut; bukan source
  aplikasi yang dihapus. Hindari memasukkannya kembali ke commit.
- Pertahankan konfigurasi lokal masing-masing anggota tim. Jangan menyelesaikan
  konflik source dengan membuang seluruh perubahan salah satu pihak.

```bash
flutter analyze
flutter test
```

Tes rules emulator beserta prasyarat Node/Java dijelaskan di
[MODERASI_FIREBASE.md](MODERASI_FIREBASE.md).

## Keterbatasan yang diketahui

- Upload Supabase memeriksa identitas Firebase dan kepemilikan UID setelah
  policy baru aktif. Kuota per pengguna belum tersedia.
- Foto lama atau file yang berhasil diunggah saat penyimpanan Firestore gagal
  tidak dihapus otomatis. Pembersihan dilakukan manual oleh pemilik project.
- Upload avatar yang selesai setelah pergantian akun tidak dipasang ke akun
  baru; file yang sempat diunggah tetap harus dibersihkan manual.
- Penghapusan akun beserta seluruh data dan foto serta penghapusan otomatis file
  Supabase belum tersedia; perlu backend tepercaya.
- Verifikasi email tersedia, tetapi akun lama yang belum diverifikasi belum
  ditolak otomatis. Perubahan email baru tercermin pada profil setelah tautan
  dikonfirmasi dan sesi berikutnya memuat ulang profil.
- AI berbasis Gemini, login Apple, pencarian suara, Firebase Linux, dan edit
  resep orang lain oleh admin sengaja tidak diubah.
- Tes lokal tidak membuktikan upload bucket live, login email/Google nyata,
  logout otomatis dua sesi Flutter, atau build seluruh platform.
