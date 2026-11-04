import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

/// Hasil ringkas untuk operasi tulis data.
class ServiceResult {
  final bool ok;
  final String message;
  final String? code;

  const ServiceResult({required this.ok, this.message = '', this.code});
}

/// Lapisan data aplikasi berbasis Cloud Firestore.
///
/// Koleksi yang dipakai:
/// - `recipes/{id}`    — resep beserta bahan & langkah
/// - `favorites/{uid__recipeId}` — resep yang disukai pengguna
/// - `reports/{id}`    — laporan resep dari komunitas
/// - `users/{uid}`     — profil pengguna (lihat [AuthService])
///
/// Bila Firebase belum dikonfigurasi, semua metode mengembalikan hasil gagal
/// sehingga pemanggil bisa jatuh ke data contoh (mode offline).
class RecipeService {
  static bool get isReady => FirebaseService.isReady;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');
  static CollectionReference<Map<String, dynamic>> get _favorites =>
      _db.collection('favorites');
  static CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');
  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static const Duration _readTimeout = Duration(seconds: 10);

  /// Urutkan dokumen terbaru ke bawah berdasarkan field `createdAt`.
  static int _newestFirst(
    DocumentSnapshot<Map<String, dynamic>> a,
    DocumentSnapshot<Map<String, dynamic>> b,
  ) =>
      _createdAtOf(b).compareTo(_createdAtOf(a));

  static int _createdAtOf(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()?['createdAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  static ServiceResult get _notConfigured =>
      ServiceResult(ok: false, message: FirebaseService.humanError);

  /// Baca query dengan waktu tunggu; bila server tak terjangkau (offline),
  /// jatuh ke cache lokal Firestore agar data tetap tampil.
  static Future<QuerySnapshot<Map<String, dynamic>>> _read(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get().timeout(_readTimeout);
    } on TimeoutException {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  /// Baca satu dokumen dengan waktu tunggu; jatuh ke cache bila offline.
  static Future<DocumentSnapshot<Map<String, dynamic>>> _readDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get().timeout(const Duration(seconds: 6));
    } on TimeoutException {
      return await ref.get(const GetOptions(source: Source.cache));
    }
  }

  static String _errorMessage(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Anda tidak punya izin untuk melakukan aksi ini.';
        case 'unavailable':
          return 'Tidak ada koneksi internet ke Firestore.';
        case 'unauthenticated':
          return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
        default:
          return e.message ?? 'Gagal mengakses database.';
      }
    }
    return 'Gagal mengakses database.';
  }

  // ───────────────────────── RESEP ─────────────────────────

  /// Ambil semua resep yang sudah diterbitkan, diurutkan terbaru.
  static Future<List<Recipe>> fetchRecipes({
    String? currentUid,
    Set<String> favoriteIds = const {},
  }) async {
    if (!isReady) return const [];
    try {
      final snap = await _read(_recipes);
      final docs = snap.docs.toList()..sort(_newestFirst);

      return docs.map((doc) {
        return Recipe.fromFirestore(
          doc.id,
          doc.data(),
          isFavorite: favoriteIds.contains(doc.id),
          currentUid: currentUid,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<ServiceResult> createRecipe({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String title,
    required String description,
    required String category,
    required String cookTime,
    required String servings,
    required String difficulty,
    required String image,
    List<String> images = const [],
    required List<Map<String, String>> ingredients,
    required List<Map<String, String>> steps,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      final now = DateTime.now();
      final code = '#RSP-${1000 + now.millisecondsSinceEpoch % 9000}';

      await _recipes.add({
        'code': code,
        'title': title,
        'description': description,
        'category': category,
        'filterKey': category.toLowerCase(),
        'cookTime': cookTime,
        'servings': servings,
        'difficulty': difficulty,
        'image': image,
        'images': images,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'likesCount': 0,
        'recooksCount': 0,
        'reportedCount': 0,
        'verified': false,
        'status': 'published',
        'ingredients': ingredients,
        'steps': steps,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ServiceResult(
        ok: true,
        code: code,
        message: 'Resep "$title" berhasil dipublikasikan!',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteRecipe(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _recipes.doc(id).delete();
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }

    // Bersihkan favorit & laporan yang menunjuk ke resep ini (best-effort).
    try {
      final favs = await _read(_favorites.where('recipeId', isEqualTo: id));
      for (final d in favs.docs) {
        await d.reference.delete();
      }
      final reps = await _read(_reports.where('recipeId', isEqualTo: id));
      for (final d in reps.docs) {
        await d.reference.delete();
      }
    } catch (_) {
      // diabaikan — resep utama sudah terhapus
    }
    return const ServiceResult(ok: true, message: 'Resep telah dihapus.');
  }

  // ───────────────────────── FAVORIT ─────────────────────────

  static String _favId(String uid, String recipeId) => '${uid}__$recipeId';

  static Future<Set<String>> fetchFavoriteIds(String uid) async {
    if (!isReady) return const {};
    try {
      final snap = await _read(_favorites.where('uid', isEqualTo: uid));
      return snap.docs.map((d) => (d.data()['recipeId'] ?? '') as String).toSet();
    } catch (_) {
      return const {};
    }
  }

  /// Tambah/hapus favorit. Mengembalikan status favorit TERBARU, atau null
  /// bila operasi gagal.
  static Future<bool?> toggleFavorite({
    required String uid,
    required String recipeId,
  }) async {
    if (!isReady) return null;
    try {
      final ref = _favorites.doc(_favId(uid, recipeId));
      final snap = await _readDoc(ref);
      if (snap.exists) {
        await ref.delete();
        return false;
      }
      await ref.set({
        'uid': uid,
        'recipeId': recipeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── LAPORAN ─────────────────────────

  static Map<String, dynamic> _reportToMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return {
      'id': doc.id,
      'recipeId': (data['recipeId'] ?? '') as String,
      'recipeTitle': (data['recipeTitle'] ?? 'Resep dihapus') as String,
      'reporterName': (data['reporterName'] ?? 'Anonim') as String,
      'reporterId': (data['reporterId'] ?? '') as String,
      'reason': (data['reason'] ?? '') as String,
      'status': (data['status'] ?? 'open') as String,
      'createdAt': data['createdAt'],
    };
  }

  static Future<List<Map<String, dynamic>>> fetchReports() async {
    if (!isReady) return const [];
    try {
      final snap = await _read(_reports);
      final docs = snap.docs.toList()..sort(_newestFirst);
      return docs.map(_reportToMap).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int> countOpenReports() async {
    final reports = await fetchReports();
    return reports.where((r) => r['status'] == 'open').length;
  }

  static Future<ServiceResult> submitReport({
    required String reporterId,
    required String reporterName,
    required String recipeId,
    required String recipeTitle,
    required String reason,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      await _reports.add({
        'recipeId': recipeId,
        'recipeTitle': recipeTitle,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const ServiceResult(
        ok: true,
        message: 'Laporan terkirim. Terima kasih sudah menjaga komunitas.',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  static Future<ServiceResult> resolveReport(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _reports.doc(id).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return const ServiceResult(ok: true, message: 'Laporan ditandai selesai.');
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteReport(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _reports.doc(id).delete();
      return const ServiceResult(ok: true, message: 'Laporan dihapus.');
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  // ───────────────────────── PENGGUNA ─────────────────────────

  static Future<List<AppUser>> fetchUsers() async {
    if (!isReady) return const [];
    try {
      final snap = await _read(_users);
      final docs = snap.docs.toList()..sort(_newestFirst);
      return docs.map((d) => AppUser.fromFirestore(d.id, d.data())).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Admin membuat "undangan" profil. Akun login-nya baru terbentuk saat
  /// pemilik email tersebut mendaftar lewat aplikasi (lihat
  /// `AuthService._claimPendingProfile`).
  static Future<ServiceResult> createPendingUser({
    required String name,
    required String email,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      final query = await _users
          .where('email', isEqualTo: email)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 6));
      final already = query.docs.isNotEmpty;
      if (already) {
        return const ServiceResult(
          ok: false,
          message: 'Email tersebut sudah terdaftar.',
        );
      }

      await _users.add({
        'name': name,
        'email': email,
        'role': 'user',
        'status': 'baru',
        'avatar': null,
        'provider': 'password',
        'code': AppUser.generateCode(),
        'pending': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ServiceResult(
        ok: true,
        message:
            'Profil "$name" dibuat. Akun aktif setelah yang bersangkutan mendaftar dengan email ini.',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  static Future<ServiceResult> setUserStatus(String uid, String status) async {
    if (!isReady) return _notConfigured;
    try {
      await _users.doc(uid).set(
        {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return const ServiceResult(ok: true, message: 'Status pengguna diperbarui.');
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteUser(String uid) async {
    if (!isReady) return _notConfigured;
    try {
      await _users.doc(uid).delete();
      return const ServiceResult(
        ok: true,
        message: 'Profil pengguna dihapus. (Akun login perlu dihapus lewat Firebase Console)',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: _errorMessage(e));
    }
  }
}
