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

Panduan lanjutan:
- [Konfigurasi bucket, upload, dan batas Supabase](SUPABASE_STORAGE.md)
- [Moderasi, aturan akses, dan tes Firestore](MODERASI_FIREBASE.md)
- [Konfigurasi Firebase per platform](FIREBASE_MIGRATION_GUIDE.md)

## Fitur aplikasi Flutter

- Resep publik: cari/filter, unggah/edit/hapus, galeri, draf teks (satu per akun;
  foto harus dipilih ulang), favorit, suka dan recook sekali per akun.
- Ulasan dan rating 1–5, ikuti koki, salin ringkasan resep untuk dibagikan,
  notifikasi aktivitas (suka/recook/ulasan) dalam aplikasi.
- Admin: laporan, status dan role pengguna, serta verifikasi resep. Admin
  pertama tetap dibuat lewat Firebase Console.
- Daftar/login, pemulihan sandi, email verifikasi, profil, tema gelap, mode tamu.

Pemilik project menyatakan `firestore.rules` terbaru sudah dipublikasikan di
Firebase Console. Akses baca resep tanpa login sudah diuji pada project nyata;
tes emulator untuk aturan lain tetap dapat dijalankan:

```bash
firebase emulators:exec --only firestore --project demo-resep-oma "npm --prefix test/firestore test"
```

Firebase CLI terbaru memerlukan Java 21 untuk emulator.

## Firestore dan akun admin

Rules terbaru sudah dipublikasikan menurut pemilik project. Pembacaan resep
tanpa login dan penolakan baca profil tanpa login sudah diuji; aturan produksi
lain belum diverifikasi langsung. Commit atau pull tidak men-deploy rules.

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

- Upload Supabase masih menggunakan akses anon. UID pada path hanya untuk
  pengelompokan, bukan verifikasi kepemilikan di server; API upload dapat
  dipanggil di luar aplikasi.
- Foto lama atau file yang berhasil diunggah saat penyimpanan Firestore gagal
  tidak dihapus otomatis. Pembersihan dilakukan manual oleh pemilik project.
- Upload avatar yang selesai setelah pergantian akun tidak dipasang ke akun
  baru; file yang sempat diunggah tetap harus dibersihkan manual.
- Penghapusan akun beserta seluruh data dan foto, penghapusan otomatis file
  Supabase, serta pagination katalog belum tersedia; perlu backend tepercaya.
- Verifikasi email tersedia, tetapi akun lama yang belum diverifikasi belum
  ditolak otomatis. Perubahan email baru tercermin pada profil setelah tautan
  dikonfirmasi dan sesi berikutnya memuat ulang profil.
- AI berbasis Gemini, login Apple, pencarian suara, Firebase Linux, dan edit
  resep orang lain oleh admin sengaja tidak diubah.
- Tes lokal tidak membuktikan upload bucket live, login email/Google nyata,
  logout otomatis dua sesi Flutter, atau build seluruh platform.
