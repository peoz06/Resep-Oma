import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'firebase_service.dart';
import 'google_auth_desktop.dart';

/// Hasil setiap operasi autentikasi.
class AuthResult {
  final bool ok;
  final String message;
  final AppUser? user;

  const AuthResult({required this.ok, this.message = '', this.user});
}

/// Lapisan autentikasi berbasis Firebase Auth.
///
/// Metode yang didukung: Email/Password, Google Sign-In, dan Anonymous (tamu).
class AuthService {
  static bool _googleInitialized = false;

  static bool get isReady => FirebaseService.isReady;

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  /// Pengguna Firebase yang sedang sesi (bisa anonim).
  static User? get firebaseUser => isReady ? _auth.currentUser : null;

  /// true bila ada sesi nyata (bukan tamu anonim dan bukan keluar).
  static bool get hasRealSession {
    final u = firebaseUser;
    return u != null && !u.isAnonymous;
  }

  static AuthResult get _notConfigured =>
      AuthResult(ok: false, message: FirebaseService.humanError);

  // ───────────────────────── SESI ─────────────────────────

  /// Pulihkan sesi yang tersimpan di perangkat saat aplikasi dibuka.
  static Future<AuthResult> restoreSession() async {
    if (!isReady) return _notConfigured;
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult(ok: false, message: 'Tidak ada sesi tersimpan.');
    }
    if (user.isAnonymous) {
      return const AuthResult(ok: false, message: 'Sesi tamu (anonim).');
    }

    final profile = await _loadProfile(user);
    if (profile == null) {
      return const AuthResult(ok: false, message: 'Profil pengguna tidak ditemukan.');
    }
    if (profile.isSuspended) {
      await _safeSignOut();
      return const AuthResult(
        ok: false,
        message: 'Akun Anda ditangguhkan oleh admin. Silakan hubungi admin.',
      );
    }
    return AuthResult(ok: true, message: 'Sesi dipulihkan.', user: profile);
  }

  /// Buat sesi anonim untuk mode tamu (tak wajib — kegagalan diabaikan).
  static Future<AuthResult> signInAnonymously() async {
    if (!isReady) return _notConfigured;
    if (_auth.currentUser != null) {
      return const AuthResult(ok: true, message: 'Sesi tamu sudah aktif.');
    }
    try {
      await _auth.signInAnonymously();
      return const AuthResult(ok: true, message: 'Masuk sebagai tamu.');
    } catch (e) {
      return AuthResult(ok: false, message: 'Gagal membuat sesi tamu: $e');
    }
  }

  static Future<void> _safeSignOut() async {
    if (!isReady) return;
    try {
      await _auth.signOut();
    } catch (_) {
      // diabaikan
    }
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // diabaikan
      }
    }
  }

  static Future<void> signOut() => _safeSignOut();

  // ───────────────────────── EMAIL / PASSWORD ─────────────────────────

  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthResult(ok: false, message: 'Registrasi gagal. Coba lagi.');
      }
      await user.updateDisplayName(name);

      // Ambil alih profil "undangan" yang dibuat admin (jika ada).
      await _claimPendingProfile(email);

      final profile = AppUser.fromAuth(
        user.uid,
        name: name,
        email: email,
        provider: 'password',
      );
      await _saveProfile(profile);
      return AuthResult(ok: true, message: 'Registrasi berhasil!', user: profile);
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      return AuthResult(ok: false, message: 'Registrasi gagal. $e');
    }
  }

  static Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthResult(ok: false, message: 'Login gagal. Coba lagi.');
      }
      final profile = await _loadProfile(user);
      if (profile == null) {
        return const AuthResult(ok: false, message: 'Profil pengguna tidak ditemukan.');
      }
      if (profile.isSuspended) {
        await _safeSignOut();
        return const AuthResult(
          ok: false,
          message: 'Akun Anda ditangguhkan oleh admin. Silakan hubungi admin.',
        );
      }
      return AuthResult(
        ok: true,
        message: 'Selamat datang kembali, ${profile.name}!',
        user: profile,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      return AuthResult(ok: false, message: 'Login gagal. $e');
    }
  }

  static Future<AuthResult> sendPasswordReset(String email) async {
    if (!isReady) return _notConfigured;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(ok: true, message: 'Tautan pemulihan dikirim ke $email.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      return AuthResult(ok: false, message: 'Gagal mengirim email. $e');
    }
  }

  // ───────────────────────── GOOGLE ─────────────────────────

  static Future<AuthResult> signInWithGoogle() async {
    if (!isReady) return _notConfigured;
    try {
      String? idToken;

      if (Platform.isWindows || Platform.isLinux) {
        // Paket `google_sign_in` tidak menyediakan implementasi untuk
        // Windows/Linux, jadi alur OAuth loopback lokal dipakai di sini.
        final desktop = await DesktopGoogleAuth.signIn();
        if (!desktop.ok) {
          return AuthResult(
            ok: false,
            message: desktop.errorDescription ??
                'Login Google gagal. Coba lagi.',
          );
        }
        idToken = desktop.idToken;
      } else {
        final google = GoogleSignIn.instance;
        await google.initialize();
        _googleInitialized = true;

        final account = await google.authenticate();
        idToken = account.authentication.idToken;
      }

      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(ok: false, message: 'Gagal mendapatkan token Google.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        return const AuthResult(ok: false, message: 'Login Google gagal. Coba lagi.');
      }

      final profile = await _loadProfile(user, provider: 'google');
      if (profile == null) {
        return const AuthResult(ok: false, message: 'Profil pengguna tidak ditemukan.');
      }
      if (profile.isSuspended) {
        await _safeSignOut();
        return const AuthResult(
          ok: false,
          message: 'Akun Anda ditangguhkan oleh admin. Silakan hubungi admin.',
        );
      }
      return AuthResult(
        ok: true,
        message: 'Berhasil masuk dengan Google, ${profile.name}!',
        user: profile,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return const AuthResult(ok: false, message: 'Login Google dibatalkan.');
      }
      return AuthResult(
        ok: false,
        message: 'Login Google gagal: ${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapGoogleError(e));
    } catch (e) {
      return AuthResult(ok: false, message: 'Login Google gagal. $e');
    }
  }

  // ───────────────────────── PROFIL ─────────────────────────

  /// Perbarui nama, email, dan/atau avatar pada profil Firestore.
  static Future<AuthResult> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    if (!isReady) return _notConfigured;
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return const AuthResult(ok: false, message: 'Masuk akun terlebih dahulu.');
    }

    try {
      final updates = <String, dynamic>{};

      if (name != null && name.trim().isNotEmpty && name.trim() != user.displayName) {
        final trimmed = name.trim();
        updates['name'] = trimmed;
        try {
          await user.updateDisplayName(trimmed);
        } catch (_) {
          // nama tampilan gagal diperbarui — profil Firestore tetap disimpan
        }
      }

      if (email != null && email.trim().isNotEmpty && email.trim() != user.email) {
        final trimmed = email.trim();
        updates['email'] = trimmed;
        try {
          await user.verifyBeforeUpdateEmail(trimmed);
        } catch (_) {
          // terlalu sering / butuh login ulang — profil Firestore tetap disimpan
        }
      }

      if (avatar != null && avatar.isNotEmpty) {
        updates['avatar'] = avatar;
      }

      if (updates.isEmpty) {
        final profile = await _loadProfile(user);
        return AuthResult(ok: true, message: 'Tidak ada perubahan.', user: profile);
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(user.uid).set(updates, SetOptions(merge: true));

      final profile = await _loadProfile(user);
      return AuthResult(ok: true, message: 'Profil berhasil disimpan.', user: profile);
    } catch (e) {
      return AuthResult(ok: false, message: 'Gagal menyimpan profil. $e');
    }
  }

  // ───────────────────────── INTERNAL ─────────────────────────

  /// Ambil (atau buat bila belum ada) dokumen profil `users/{uid}`.
  /// Mengembalikan null untuk sesi anonim.
  static Future<AppUser?> _loadProfile(
    User user, {
    String? provider,
    bool createIfMissing = true,
  }) async {
    if (user.isAnonymous) return null;

    final fallback = AppUser.fromAuth(
      user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Pengguna',
      email: user.email ?? '',
      avatar: user.photoURL,
      provider: provider ?? 'password',
    );

    if (!isReady) return fallback;

    try {
      final snap = await _users
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 6));
      if (snap.exists) return AppUser.fromFirestore(user.uid, snap.data()!);
      if (!createIfMissing) return fallback;
      await _saveProfile(fallback);
      return fallback;
    } catch (_) {
      // Firestore tak terjangkau: pakai data dari akun Auth saja.
      return fallback;
    }
  }

  static Future<void> _saveProfile(AppUser profile) async {
    try {
      await _users.doc(profile.uid).set(profile.toFirestore());
    } catch (_) {
      // biarkan — profil akan dibuat ulang pada kunjungan berikutnya
    }
  }

  /// Hapus profil "undangan" yang dibuat admin untuk email ini.
  static Future<void> _claimPendingProfile(String email) async {
    try {
      final snap = await _users
          .where('email', isEqualTo: email)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 6));
      for (final doc in snap.docs) {
        if (doc.data()['pending'] == true) {
          await doc.reference.delete();
        }
      }
    } catch (_) {
      // diabaikan
    }
  }

  /// Pesan kesalahan khusus login Google (konteksnya berbeda dengan email,
  /// mis. `invalid-credential` bukan berarti kata sandi salah).
  static String _mapGoogleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-idp-response':
      case 'missing-or-invalid-nonce':
      case 'invalid-argument':
        return 'Login Google gagal. Pastikan provider Google aktif di '
            'Firebase Console dan SHA-1 aplikasi sudah terdaftar '
            '(lihat FIREBASE_MIGRATION_GUIDE.md).';
      case 'operation-not-allowed':
        return 'Login Google belum diaktifkan di Firebase Console.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      default:
        return _mapError(e);
    }
  }

  static String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau kata sandi salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan di Firebase Console.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Coba lagi.';
      case 'requires-recent-login':
        return 'Sesi kedaluwarsa. Silakan masuk kembali.';
      case 'invalid-action-code':
      case 'expired-action-code':
        return 'Tautan tidak valid atau sudah kedaluwarsa.';
      default:
        return e.message ?? 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
