# Foto di Supabase Storage

Firebase Auth tetap menangani login email/password dan Google. Firestore tetap
menyimpan profil, resep, dan URL foto. Supabase hanya menyimpan file gambar dan
memverifikasi token Firebase lewat integrasi Third-Party Auth; tidak ada login
Supabase terpisah.

## Konfigurasi lokal

Salin `supabase.example.json` menjadi `supabase.local.json`, lalu isi URL project
dan publishable key. `supabase.local.json` sudah masuk `.gitignore`.
Jangan gunakan secret key atau `service_role` di aplikasi.

```bash
flutter pub get
flutter run --dart-define-from-file=supabase.local.json
```

Untuk browser:

```bash
flutter run -d chrome --dart-define-from-file=supabase.local.json
```

Untuk build, berikan konfigurasi yang sama:

```bash
flutter build apk --dart-define-from-file=supabase.local.json
flutter build web --dart-define-from-file=supabase.local.json
```

Konfigurasi dibaca saat kompilasi; setelah menggantinya, hentikan dan jalankan
ulang aplikasi. Publishable key tetap bisa dibaca dari aplikasi hasil build;
file yang di-ignore hanya mencegah nilai lokal ikut masuk Git.

Tanpa konfigurasi Supabase, aplikasi tetap terbuka dan URL foto lama tetap
ditampilkan. Upload baru menampilkan error konfigurasi. Kesiapan Storage
terpisah dari kesiapan Firebase, dan tidak menjamin koneksi/policy bucket benar.

## Aktifkan akses upload

1. Di Supabase Dashboard, buka **Authentication → Third-party Auth** dan
   tambahkan proyek Firebase `resep-oma`. Untuk staging, cocokkan ID Firebase
   yang didaftarkan dengan `iss` dan `aud` di migrasi.
2. Terapkan [`20261123000100_secure_photo_uploads.sql`](supabase/migrations/20261123000100_secure_photo_uploads.sql)
   melalui migrasi Supabase atau sekali lewat SQL Editor. Tinjau policy lama
   yang tidak diperlukan. Policy baru tetap memblokir upload tanpa identitas
   meski policy `INSERT` permisif lama masih ada.
3. Uji Android di proyek tes sebelum mengaktifkan policy produksi. Build lama
   yang tidak mengirim token Firebase tidak bisa lagi mengunggah foto.

- Bucket public: `avatars` dan `recipe-images`.
- Aplikasi hanya bisa INSERT dengan token Firebase valid dari akun email atau
  Google. PostgreSQL dapat memakai peran `anon` untuk token Firebase tanpa custom
  claim `role`; policy tetap menolak permintaan tanpa identitas Firebase.
- Path di dalam bucket: `<firebaseUid>/<timestamp-mikrodetik>.<ext>`.
- UID pada path harus sama dengan `sub` token yang diverifikasi Supabase.
- Maksimal 5 MiB (5 × 1024 × 1024 byte) per foto; JPEG, PNG, atau WebP.
- Upload menggunakan bytes, content type berdasarkan header file, dan `upsert: false`.
- Bucket juga membatasi ukuran dan MIME. Konversikan HEIC/GIF sebelum upload.

Policy tidak membaca status moderasi Firestore. Jika akses akun ke Storage juga
perlu dihentikan, tangani akun dan token lewat Firebase Auth. Kuota per akun dan
pemeriksaan isi file di server belum tersedia.

## Penyimpanan dan kegagalan

Foto baru mendapat public URL Supabase, lalu URL tersebut disimpan ke Firestore.
URL Firebase lama tetap dipakai tanpa migrasi atau upload ulang. Foto admin
mengikuti profil akun yang sedang login; ketuk foto di pengaturan admin untuk
membuka halaman profil dan mengganti fotonya.

Tidak ada operasi update/delete file di Supabase. Jika Firestore gagal setelah
upload, aplikasi menampilkan error dan membiarkan file tetap tersimpan. Form
resep menyimpan URL hasil upload agar percobaan simpan ulang tidak mengunggah
file yang sama. File lama setelah penggantian foto/penghapusan resep juga tetap
ada; pembersihan dilakukan manual oleh pemilik project bila diperlukan.

Upload avatar diikat ke UID awal: jika akun berganti saat upload, foto tidak
dipasang ke akun baru. File yang terlanjur diunggah tetap perlu dibersihkan manual.

## Pemeriksaan

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Setelah migrasi di basis data tes, jalankan
[`storage_photo_policy.sql`](supabase/tests/storage_photo_policy.sql)
dengan `psql -v ON_ERROR_STOP=1 -f supabase/tests/storage_photo_policy.sql`.
Tes SQL mengecek policy dan konfigurasi bucket, bukan verifikasi JWT atau upload
HTTP. Uji manual di Android: login, ganti avatar,
buat/edit resep dengan foto, buka kembali aplikasi, dan pastikan URL di Firestore
mengarah ke bucket public yang benar. Periksa juga penolakan ukuran/tipe file
serta penolakan upload tanpa akun.
