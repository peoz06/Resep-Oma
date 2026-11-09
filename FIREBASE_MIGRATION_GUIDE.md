# Panduan Migrasi Firebase — Resep Oma (dapurkita)

File ini adalah lanjutan dari rewrite service layer yang sudah selesai.
Semua layanan Firebase sudah ditulis di `lib/services/` dan siap dipakai
setelah project Firebase dibuat dan `flutterfire configure` dijalankan.

## 1. Status kode saat ini (sudah selesai)

| File | Keterangan |
|------|------------|
| `lib/services/firebase_service.dart` | Inisialisasi Firebase + siap-mode offline bila belum terkonfigurasi |
| `lib/services/auth_service.dart` | Auth: Email/Password, Google Sign-In, Anonymous, restore sesi, update profil |
| `lib/services/recipe_service.dart` | Firestore: resep, favorit, laporan, pengguna (admin via field `role`) |
| `lib/services/storage_service.dart` | Firebase Storage + `image_picker` untuk unggah foto resep & avatar |
| `lib/models/user_model.dart` | Model `AppUser` (profil `users/{uid}`, role via field bukan custom claim) |
| `lib/models/recipe_model.dart` | `Recipe.fromFirestore` (ID String), `AdminUser.fromAppUser` |
| `lib/screens/main_navigation_screen.dart` | Uid String, auth state listener, guest mode, Firebase bootstrap |
| `lib/screens/auth_screens.dart` | Login/Register via Firebase Auth + Google + Lupa Sandi |
| `lib/screens/unggah_resep_screen.dart` | `image_picker` + Storage (ganti `_cyclePhoto` mock) |
| `lib/screens/profil_screen.dart` | Update profil + upload avatar ke Storage |
| `lib/screens/admin_screens.dart` | Firestore (ganti `ApiService`), String uid, `createPendingUser` |
| `lib/widgets/recipe_detail_sheet.dart` | Laporan via `RecipeService`, String uid |
| `lib/widgets/app_cached_image.dart` | Dukung URL http + file lokal |
| `lib/main.dart` | Panggil `FirebaseService.init()` sebelum `runApp` |
| `lib/services/api_service.dart` | **Dihapus** |
| `pubspec.yaml` | `http` dihapus; paket Firebase + `image_picker` sudah terpasang |
| `test/widget_test.dart` | Smoke test lulus (mode offline karena Firebase belum terkonfigurasi di test) |

## 2. Langkah-langkah buat project Firebase (Console Google)

Buka https://console.firebase.google.com dengan akun Google Anda.

### 2a. Buat project
1. Klik **"Add project"** / **"Buat project"**.
2. Masukkan nama project, contoh: `resep-oma` (atau `dapurkita`).
3. **Google Analytics**: pilih sesuai keinginan (bisa diaktifkan atau tidak).
4. Klik **Create project**, tunggu hingga selesai, lalu klik **Continue**.

### 2b. Siapkan aplikasi Android
1. Di halaman project overview, klik ikon **Android** (platfrom Android) atau **"Add app" → Android**.
2. Isi:
   - **Android package name**: `com.example.dapurkita` (lihat `android/app/build.gradle.kts` → `namespace` / `compileSdk`). Jika belum ada namespace, defaultnya adalah `com.example.dapurkita`.
   - **App nickname**: `Resep Oma` (opsional).
   - **Debug signing certificate SHA-1**: **Diperlukan untuk Google Sign-In**. Lihat langkah 2c di bawah.
3. Klik **Register app**.
4. Unduh `google-services.json` → simpan di `android/app/google-services.json`.
5. Klik **Next** hingga selesai (bisa skip langkah menambahkan SDK secara manual karena FlutterFire akan menangani).

### 2c. Dapatkan SHA-1 (debug) untuk Google Sign-In
Jalankan di terminal (di folder project):
```bash
cd android
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
```
Password keystore: `android`.
Salin **SHA1** yang muncul. Masukkan ke Firebase Console → Project settings → Your apps → Android app → **Add fingerprint**.

> Untuk build release nanti, tambahkan juga SHA-1 certificate release (keytool dengan keystore produksi).

### 2d. Siapkan aplikasi iOS (opsional, bila akan build di macOS)
1. Di Firebase Console, klik ikon **iOS** → **Add app**.
2. **iOS bundle ID**: lihat `ios/Runner/Info.plist` → `CFBundleIdentifier` (biasanya `com.example.dapurkita`).
3. Unduh `GoogleService-Info.plist` → simpan di `ios/Runner/GoogleService-Info.plist` dan tambahkan ke Xcode project.
4. Aktifkan **Push Notifications** / **Background Modes** jika diperlukan (bisa skip untuk awal).

### 2e. Aktifkan metode autentikasi
Di Firebase Console → **Build → Authentication → Get started** → tab **Sign-in method**:
- **Email/Password**: Enable.
- **Google**: Enable (pilih email support project Anda).
- **Anonymous**: Enable (untuk mode tamu/guest).

Simpan masing-masing.

### 2f. Buat database Firestore
Di Firebase Console → **Build → Firestore Database → Create database**:
- Pilih **Start in test mode** (untuk development; aturan akan dikencangkan setelahnya lewat Security Rules di bawah).
- Pilih lokasi terdekat (contoh: `nam5` / `asia-southeast1`).
- Klik **Enable**.

### 2g. Buat bucket Storage
Di Firebase Console → **Build → Storage → Get started**:
- Pilih **Start in test mode**.
- Pilih lokasi yang sama dengan Firestore.
- Klik **Done**.

### 2h. Google Sign-In di Windows/Linux (OAuth loopback)

Plugin `google_sign_in` **tidak menyediakan implementasi untuk Windows/Linux**, jadi aplikasi
menjalankan alur OAuth 2.0 sendiri lewat `lib/services/auth_service.dart` →
`lib/services/google_auth_desktop.dart`:

1. Aplikasi membuka server HTTP kecil di `http://127.0.0.1:<port>/callback`.
2. Browser sistem dibuka ke halaman `accounts.google.com` dengan
   `response_type=id_token` (alur implicit, **tanpa `client_secret`** — aman dibagikan di aplikasi desktop).
3. Google mengembalikan `id_token` ke halaman bridge → diteruskan ke aplikasi.
4. Aplikasi memverifikasi token: `iss`, `aud` (client ID), `nonce` acak, dan `exp`.
   Timeout proses: **3 menit**.

**Yang harus disiapkan di Google Cloud Console** (APIs & Services → Credentials →
OAuth 2.0 Client IDs → buat/klik client bertipe **Web application**, client ID harus sama dengan
yang dipakai Firebase / `android/app/google-services.json`):

- **Authorized redirect URIs** → tambahkan:
  ```
  http://127.0.0.1
  ```
  Google secara khusus mengizinkan redirect URI *loopback* dengan port bebas (port yang dipakai
  aplikasi dibuat dinamis), jadi cukup daftarkan `http://127.0.0.1` (boleh juga `http://localhost`).
- Client ID tersebut harus persis sama dengan nilai `DesktopGoogleAuth.clientId`
  (`581136907560-umfvnf7fekg18qtjhmuh07ie3st1nuci.apps.googleusercontent.com`).

Jika redirect URI belum terdaftar, browser akan menampilkan error *"The redirect URI in the
request, ... does not match the ones authorized for the OAuth client"* dan proses login berhenti.

## 3. Install FlutterFire CLI & jalankan configure

Di terminal (root project):
```bash
# Install FlutterFire CLI (kalau belum ada)
dart pub global activate flutterfire_cli

# Pastikan PATH mencakup ~/.pub-cache/bin (lihat output perintah di atas)

# Login ke Google
flutterfire login

# Konfigurasi project Flutter dengan Firebase
flutterfire configure
```

`flutterfire configure` akan:
- Mendeteksi project Firebase yang tersedia (pilih project `resep-oma`).
- Mendeteksi aplikasi Android (dan iOS jika ada) yang telah terdaftar.
- Menghasilkan file `lib/firebase_options.dart` (DefaultFirebaseOptions).
- Menyisipkan plugin konfigurasi ke `android/app/build.gradle.kts` dan `ios/Runner/Info.plist` (jika diperlukan).
- Menyalin `google-services.json` ke `android/app/`.

### Perhatian untuk Android
Pastikan `android/app/build.gradle.kts` sudah memiliki:
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")   // <- ditambahkan flutterfire configure
}
```
dan di bagian bawah:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

Pastikan `android/build.gradle.kts` (project level) memiliki dependency classpath:
```kotlin
dependencies {
    classpath("com.android.tools.build:gradle:8.x")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.x")
    classpath("com.google.gms:google-services:4.4.x")  // <- sesuai versi terbaru
}
```

### Perhatian untuk iOS
Tambahkan izin kamera & foto di `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Resep Oma perlu akses kamera untuk mengambil foto resep.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Resep Oma perlu akses galeri untuk memilih foto resep.</string>
```
Dan untuk Google Sign-In iOS, tambahkan URL scheme dengan `REVERSED_CLIENT_ID` dari `GoogleService-Info.plist`.

## 4. Security Rules (Firestore & Storage)

Di Firebase Console → **Build → Firestore Database → Rules** → ganti dengan:

```rules
service cloud.firestore {
  match /databases/{database}/documents {
    // Pengguna hanya bisa baca/tulis profil sendiri
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      // Admin bisa baca semua profil
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }

    // Resep: semua bisa baca, hanya pemulis yang bisa tulis/hapus
    match /recipes/{recipeId} {
      allow read: if true;
      allow create: if request.auth != null && !request.auth.token.anonymous;
      allow update, delete: if request.auth != null &&
        resource.data.authorId == request.auth.uid;
    }

    // Favorit: milik pengguna sendiri
    match /favorites/{favId} {
      allow read, write: if request.auth != null && request.auth.uid == request.resource.data.uid;
    }

    // Laporan: semua user terautentikasi bisa buat; admin bisa baca/update/hapus
    match /reports/{reportId} {
      allow create: if request.auth != null && !request.auth.token.anonymous;
      allow read, update, delete: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }
  }
}
```

Di Firebase Console → **Build → Storage → Rules** → ganti dengan:

```rules
service firebase.storage {
  match /b/{bucket}/o {
    // Foto resep: publik baca, user terautentikasi tulis di folder recipes/
    match /recipes/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && !request.auth.token.anonymous;
    }

    // Avatar profil: publik baca, pemilik tulis di folder avatars/{uid}/
    match /avatars/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Klik **Publish** setelah setiap perubahan.

## 5. Mode tamu (guest) & Anonymous Auth

- Saat aplikasi dibuka tanpa sesi, `MainNavigationScreen` otomatis memanggil `AuthService.signInAnonymously()`.
- Tamu bisa jelajahi resep; unggah/favorit/laporan memerlukan login nyata (Email/Password atau Google).
- Kode secara sengaja **tidak** menggunakan custom claim untuk admin; admin ditandai lewat field `role` di dokumen `users/{uid}` (lihat `AppUser.role`).

## 6. Jalankan aplikasi

```bash
flutter pub get
flutter run
```

Jika Firebase belum di-`configure`, aplikasi tetap jalan dalam mode offline (data contoh `MockData`), sesuai keputusan awal.

## 7. File yang perlu Anda siapkan sendiri (hasil dari langkah 2 & 3)

- `android/app/google-services.json` — unduh dari Firebase Console (Android app).
- `ios/Runner/GoogleService-Info.plist` — unduh dari Firebase Console (iOS app, opsional).
- `lib/firebase_options.dart` — dihasilkan otomatis oleh `flutterfire configure`.

## 8. Troubleshooting cepat

| Gejala | Penyebab kemungkinan | Solusi |
|--------|---------------------|--------|
| `MissingPluginException` | Plugin Firebase belum terinstal di platform | `flutter pub get` + rebuild ulang (Android: `cd android && ./gradlew clean`) |
| `No Firebase App` | `firebase_options.dart` belum ada / `flutterfire configure` belum dijalankan | Jalankan langkah 3 |
| Google Sign-In gagal (`clientConfigurationError`) | SHA-1 belum ditambahkan di Firebase Console | Tambahkan SHA-1 debug (langkah 2c) |
| Tombol Google di Windows/Linux tidak membuka browser | `url_launcher` tidak dapat membuka URL | `flutter pub get` lalu build ulang; cek juga tidak ada pemblokir browser |
| Browser terbuka, tapi muncul error `redirect_uri ... does not match` | `http://127.0.0.1` belum terdaftar di OAuth client | Tambahkan **Authorized redirect URI** `http://127.0.0.1` di Google Cloud Console (langkah 2h) |
| Setelah menyetujui di browser, aplikasi tetap loading lalu timeout (3 menit) | Browser tidak mengembalikan token (tab ditutup sebelum selesai) | Biarkan halaman konfirmasi terbuka sampai kembali ke aplikasi; atau klik tombol Google lagi |
| `permission-denied` Firestore | Security Rules belum diatur | Terapkan rules langkah 4 |
| Aplikasi tetap mode offline meski `flutterfire configure` selesai | `google-services.json` tidak di lokasi yang benar | Simpan di `android/app/google-services.json`, lalu restart |

Selamat! Setelah langkah 2–3 selesai, aplikasi Resep Oma sudah berjalan sepenuhnya pada Firebase (Auth, Firestore, Storage) sambil tetap mempertahankan UI/UX asli dan mode tamu.
