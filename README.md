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

## Firestore dan akun admin

Rules Firestore **sudah live** sesuai `firestore.rules`, berdasarkan konfirmasi
pemilik project yang menerapkannya melalui Firebase Console. Commit atau pull
repository tidak melakukan deploy rules. Agent tidak memverifikasi Console langsung.

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
- Hindari mengganti akun saat upload avatar berjalan; pengikatan penyimpanan
  hasil upload ke UID awal belum diperbaiki.
- Tes lokal tidak membuktikan upload bucket live, login email/Google nyata,
  logout otomatis dua sesi Flutter, atau build seluruh platform.
