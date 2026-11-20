# Foto di Supabase Storage

Firebase Auth tetap menangani login email/password dan Google. Firestore tetap
menyimpan profil, resep, dan URL foto. Supabase hanya menyimpan file gambar.
Tidak ada integrasi Third-Party Auth, custom claim, atau sesi login Supabase.

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

## Bucket dan batas upload

- Bucket public: `avatars` dan `recipe-images`.
- Policy hanya INSERT untuk `anon`/`authenticated`; aplikasi memakai `anon`.
- Path di dalam bucket: `<firebaseUid>/<timestamp-mikrodetik>.<ext>`.
- Maksimal 5 MiB (5 × 1024 × 1024 byte) per foto; JPEG, PNG, atau WebP.
- Upload menggunakan bytes, content type berdasarkan header file, dan `upsert: false`.
- Konversikan HEIC/GIF sebelum upload. Atur batas ukuran dan MIME pada bucket juga.

UID dipakai untuk pengelompokan, bukan bukti kepemilikan di server. Policy anon
memungkinkan siapa pun yang mengakses API mengunggah file; pemeriksaan login dan
validasi Flutter bisa dilewati. Jalur ini tidak aman untuk membatasi upload per
pengguna atau mencegah penyalahgunaan kuota. Aktifkan autentikasi tepercaya dan
policy kepemilikan sebelum penggunaan publik berskala besar.

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
dipasang ke akun baru. File yang terlanjur diunggah tetap perlu dibersihkan
manual. Policy upload anon tidak bisa menjamin kepemilikan file di server;
batasi akses bucket dengan backend tepercaya sebelum digunakan secara publik.

## Pemeriksaan

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Tes lokal tidak mengunggah file ke bucket live. Uji manual: login, ganti avatar,
buat/edit resep dengan foto, buka kembali aplikasi, dan pastikan URL di Firestore
mengarah ke bucket public yang benar. Periksa juga penolakan ukuran/tipe file
dan pesan gagal menyimpan ketika Firestore menolak operasi.
