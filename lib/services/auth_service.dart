import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
/// Metode yang didukung: Email/Password dan Google Sign-In; tamu tanpa sesi.
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

    return _completeSignIn(user);
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

  static Future<void> signOut() async {
    if (!isReady) return;
    await _auth.signOut();
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Sesi Firebase sudah berakhir; kegagalan Google tidak mengembalikannya.
      }
    }
  }

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
        return const AuthResult(
            ok: false, message: 'Registrasi gagal. Coba lagi.');
      }
      await user.updateDisplayName(name);

      final profile = AppUser.fromAuth(
        user.uid,
        name: name,
        email: email,
        provider: 'password',
      );
      try {
        await _saveProfile(profile);
      } on TimeoutException {
        // Timeout tidak membatalkan penulisan Firestore yang masih berjalan.
        await _safeSignOut();
        return const AuthResult(ok: false,
            message: 'Akun sudah dibuat, tetapi penyimpanan profil belum terkonfirmasi. Silakan masuk kembali; tidak perlu mendaftar ulang.');
      } catch (e) {
        // Jangan tinggalkan akun Auth yatim bila profil wajib gagal dibuat.
        try {
          await user.delete();
        } catch (_) {
          await _safeSignOut();
          return const AuthResult(ok: false,
              message: 'Profil gagal disimpan. Akun mungkin sudah dibuat; coba masuk atau reset sandi.');
        }
        return AuthResult(ok: false, message: profileErrorMessage(e));
      }
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } catch (_) {
          // Akun tetap bisa dipakai; email verifikasi dapat dikirim ulang dari profil.
        }
      }
      return await _completeSignIn(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      await _safeSignOut();
      return AuthResult(ok: false, message: profileErrorMessage(e));
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
      return await _completeSignIn(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      await _safeSignOut();
      return AuthResult(ok: false, message: profileErrorMessage(e));
    }
  }

  static Future<AuthResult> sendPasswordReset(String email) async {
    if (!isReady) return _notConfigured;
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
          ok: true, message: 'Tautan pemulihan dikirim ke $email.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      return AuthResult(ok: false, message: 'Gagal mengirim email. $e');
    }
  }

  static Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!isReady) return _notConfigured;
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.email == null ||
        !user.providerData.any((provider) => provider.providerId == 'password')) {
      return const AuthResult(ok: false, message: 'Fitur ini hanya untuk akun email dan kata sandi.');
    }
    if (oldPassword.isEmpty || newPassword.length < 6) {
      return const AuthResult(ok: false, message: 'Isi kata sandi lama dan kata sandi baru minimal 6 karakter.');
    }
    try {
      await user.reauthenticateWithCredential(EmailAuthProvider.credential(
        email: user.email!, password: oldPassword,
      ));
      await user.updatePassword(newPassword);
      return const AuthResult(ok: true, message: 'Kata sandi berhasil diubah.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (_) {
      return const AuthResult(ok: false, message: 'Gagal mengubah kata sandi. Coba lagi.');
    }
  }

  static Future<AuthResult> sendVerificationEmail() async {
    if (!isReady) return _notConfigured;
    final user = firebaseUser;
    if (user == null || user.isAnonymous || user.email == null) {
      return const AuthResult(ok: false, message: 'Masuk dengan email terlebih dahulu.');
    }
    try {
      await user.reload();
      if (_auth.currentUser?.emailVerified == true) {
        return const AuthResult(ok: true, message: 'Email sudah terverifikasi.');
      }
      await _auth.currentUser!.sendEmailVerification();
      return const AuthResult(ok: true, message: 'Tautan verifikasi dikirim ke email Anda.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (_) {
      return const AuthResult(ok: false, message: 'Gagal mengirim verifikasi. Coba lagi.');
    }
  }

  // ───────────────────────── GOOGLE ─────────────────────────

  static Future<AuthResult> signInWithGoogle() async {
    if (!isReady) return _notConfigured;
    try {
      if (kIsWeb) {
        final cred = await _auth.signInWithPopup(GoogleAuthProvider());
        if (cred.user == null) {
          return const AuthResult(
              ok: false, message: 'Login Google gagal. Coba lagi.');
        }
        return await _completeSignIn(cred.user!, provider: 'google');
      }
      String? idToken;

      if (Platform.isWindows || Platform.isLinux) {
        // Paket `google_sign_in` tidak menyediakan implementasi untuk
        // Windows/Linux, jadi alur OAuth loopback lokal dipakai di sini.
        final desktop = await DesktopGoogleAuth.signIn();
        if (!desktop.ok) {
          return AuthResult(
            ok: false,
            message:
                desktop.errorDescription ?? 'Login Google gagal. Coba lagi.',
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
        return const AuthResult(
            ok: false, message: 'Gagal mendapatkan token Google.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        return const AuthResult(
            ok: false, message: 'Login Google gagal. Coba lagi.');
      }

      return await _completeSignIn(user, provider: 'google');
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
      await _safeSignOut();
      return AuthResult(ok: false, message: profileErrorMessage(e));
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
      return const AuthResult(
          ok: false, message: 'Masuk akun terlebih dahulu.');
    }

    try {
      final updates = <String, dynamic>{};

      final newName = name?.trim();
      if (newName != null && newName.isNotEmpty) {
        updates['name'] = newName;
        if (newName != user.displayName) {
          try {
            await user.updateDisplayName(newName);
          } catch (_) {
            // nama tampilan gagal diperbarui — profil Firestore tetap disimpan
          }
        }
      }

      final newEmail = email?.trim();
      final emailChanged = newEmail != null && newEmail.isNotEmpty && newEmail != user.email;
      if (emailChanged) {
        // Firestore hanya mengikuti email Auth sesudah tautan konfirmasi dipakai.
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      if (avatar != null && avatar.isNotEmpty) {
        updates['avatar'] = avatar;
      }

      if (updates.isEmpty) {
        final profile = await _loadProfile(user);
        return AuthResult(
            ok: true,
            message: emailChanged
                ? 'Konfirmasi perubahan email melalui tautan yang dikirim. Profil belum mengubah email.'
                : 'Tidak ada perubahan.',
            user: profile);
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(user.uid).set(updates, SetOptions(merge: true));

      final profile = await _loadProfile(user);
      if (updates.containsKey('name') || updates.containsKey('avatar')) {
        try {
          await _syncRecipeAuthors(profile);
        } catch (_) {
          return AuthResult(ok: true, user: profile,
              message: 'Profil tersimpan, tetapi nama/foto pada resep lama belum diperbarui. Coba simpan profil lagi.');
        }
      }
      return AuthResult(
          ok: true,
          message: emailChanged
              ? 'Nama disimpan. Konfirmasi email baru melalui tautan yang dikirim.'
              : 'Profil berhasil disimpan.',
          user: profile);
    } on FirebaseAuthException catch (e) {
      return AuthResult(ok: false, message: _mapError(e));
    } catch (e) {
      return AuthResult(ok: false, message: profileErrorMessage(e));
    }
  }

  // ───────────────────────── INTERNAL ─────────────────────────

  /// Semua metode login melewati pemeriksaan status yang sama dan gagal tertutup.
  static Future<AuthResult> _completeSignIn(User user,
      {String? provider}) async {
    try {
      final profile = await _loadProfile(user, provider: provider);
      if (!profile.isActive) {
        await _safeSignOut();
        return AuthResult(ok: false, message: profile.accessDeniedMessage);
      }
      return AuthResult(
          ok: true, message: 'Selamat datang, ${profile.name}!', user: profile);
    } catch (e) {
      await _safeSignOut();
      return AuthResult(ok: false, message: profileErrorMessage(e));
    }
  }

  static String profileErrorMessage(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Akses profil ditolak. Silakan masuk kembali atau hubungi admin.';
    }
    return 'Profil belum dapat diverifikasi. Periksa koneksi lalu masuk kembali.';
  }

  static Stream<AppUser?> watchProfile(String uid) =>
      _users.doc(uid).snapshots().map(
            (doc) =>
                doc.exists ? AppUser.fromFirestore(doc.id, doc.data()!) : null,
          );

  static Future<void> _syncRecipeAuthors(AppUser profile) async {
    final recipes = await FirebaseFirestore.instance.collection('recipes')
        .where('authorId', isEqualTo: profile.uid).get();
    for (var start = 0; start < recipes.docs.length; start += 400) {
      final batch = FirebaseFirestore.instance.batch();
      var changed = false;
      for (final recipe in recipes.docs.skip(start).take(400)) {
        if (recipe.data()['authorName'] != profile.name ||
            recipe.data()['authorAvatar'] != profile.avatar) {
          changed = true;
          batch.update(recipe.reference, {
            'authorName': profile.name,
            'authorAvatar': profile.avatar,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (changed) await batch.commit();
    }
  }

  /// Ambil (atau buat bila belum ada) dokumen profil `users/{uid}` dari server.
  static Future<AppUser> _loadProfile(
    User user, {
    String? provider,
  }) async {
    final fallback = AppUser.fromAuth(
      user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Pengguna',
      email: user.email ?? '',
      avatar: user.photoURL,
      provider: provider ?? 'password',
    );

    final snap = await _users
        .doc(user.uid)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 6));
    if (snap.exists) {
      final profile = AppUser.fromFirestore(user.uid, snap.data()!);
      if (profile.isActive && user.email != null && user.email != profile.email) {
        await _users.doc(user.uid).update({
          'email': user.email, 'updatedAt': FieldValue.serverTimestamp(),
        });
        return profile.copyWith(email: user.email);
      }
      return profile;
    }
    await _saveProfile(fallback);
    return fallback;
  }

  static Future<void> _saveProfile(AppUser profile) => _users
      .doc(profile.uid)
      .set(profile.toFirestore())
      .timeout(const Duration(seconds: 8));

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
