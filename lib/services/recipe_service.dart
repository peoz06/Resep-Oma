import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
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
/// - `likes`, `recooks`, `follows` — aktivitas per akun
/// - `recipes/{id}/comments` — ulasan dan rating
/// - `notifications` — aktivitas resep penulis
/// - `drafts/{uid}` — satu draf teks per akun
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
  static CollectionReference<Map<String, dynamic>> get _likes =>
      _db.collection('likes');
  static CollectionReference<Map<String, dynamic>> get _recooks =>
      _db.collection('recooks');
  static CollectionReference<Map<String, dynamic>> get _follows =>
      _db.collection('follows');
  static CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  static CollectionReference<Map<String, dynamic>> get _drafts =>
      _db.collection('drafts');
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

  static String errorMessage(Object e) {
    if (e is TimeoutException) {
      return 'Koneksi ke Firestore terlalu lama. Coba muat resep lagi.';
    }
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'Anda tidak punya izin untuk melakukan aksi ini.';
        case 'unavailable':
          return 'Tidak ada koneksi internet ke Firestore.';
        case 'unauthenticated':
          return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
        default:
          return 'Gagal mengakses database. Silakan coba lagi.';
      }
    }
    return 'Gagal mengakses database.';
  }

  // ───────────────────────── RESEP ─────────────────────────

  /// Ambil semua resep yang sudah diterbitkan, diurutkan terbaru.
  static Future<List<Recipe>> fetchRecipes({
    String? currentUid,
    Set<String> favoriteIds = const {},
    Map<String, DateTime> favoriteDates = const {},
    Set<String> likedIds = const {},
  }) async {
    if (!isReady) return const [];
    // Cache kosong saat koneksi lambat bukan bukti katalog di server kosong.
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _recipes.get(const GetOptions(source: Source.server))
          .timeout(_readTimeout);
    } on TimeoutException {
      snap = await _recipes.get(const GetOptions(source: Source.cache));
      if (snap.docs.isEmpty) rethrow;
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      snap = await _recipes.get(const GetOptions(source: Source.cache));
      if (snap.docs.isEmpty) rethrow;
    }
    final docs = snap.docs.toList()..sort(_newestFirst);
    return docs
        .map((doc) => Recipe.fromFirestore(
              doc.id,
              doc.data(),
              isFavorite: favoriteIds.contains(doc.id),
              favoritedAt: favoriteDates[doc.id],
              isLiked: likedIds.contains(doc.id),
              currentUid: currentUid,
            ))
        .toList();
  }

  static Future<ServiceResult> saveRecipe({
    String? recipeId,
    required String authorId,
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
    if (!AuthService.hasRealSession ||
        AuthService.firebaseUser?.uid != authorId) {
      return const ServiceResult(
          ok: false,
          message: 'Masuk dengan akun pemilik resep terlebih dahulu.');
    }
    try {
      final data = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'filterKey': category.toLowerCase(),
        'cookTime': cookTime,
        'servings': servings,
        'difficulty': difficulty,
        'image': image,
        'images': images,
        'ingredients': ingredients,
        'steps': steps,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (recipeId != null) {
        return await _db.runTransaction<ServiceResult>((transaction) async {
          final ref = _recipes.doc(recipeId);
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            return const ServiceResult(
                ok: false, message: 'Resep sudah tidak tersedia.');
          }
          if (snapshot.data()?['authorId'] != authorId) {
            final actor = await transaction.get(_users.doc(authorId));
            final data = actor.data();
            if (data == null ||
                data['role'] != 'admin' ||
                (data['status'] ?? 'active') != 'active') {
              return const ServiceResult(
                  ok: false,
                  message: 'Anda hanya bisa mengedit resep sendiri.');
            }
          }
          transaction.update(ref, data);
          return const ServiceResult(
              ok: true, message: 'Perubahan resep berhasil disimpan.');
        });
      }

      final now = DateTime.now();
      final code = '#RSP-${1000 + now.millisecondsSinceEpoch % 9000}';
      final profile = await _readDoc(_users.doc(authorId));
      if (profile.data() == null) {
        return const ServiceResult(ok: false, message: 'Profil penulis tidak ditemukan.');
      }
      await _recipes.add({
        ...data,
        'code': code,
        'authorId': authorId,
        'authorName': profile.data()!['name'],
        'authorAvatar': profile.data()!['avatar'],
        'likesCount': 0,
        'recooksCount': 0,
        'verified': false,
        'status': 'published',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return ServiceResult(
        ok: true,
        code: code,
        message: 'Resep "$title" berhasil dipublikasikan!',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteRecipe(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _recipes.doc(id).delete();
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }

    // Favorit milik pengguna lain dan laporan moderasi tetap disimpan, bukan dihapus oleh client.
    return const ServiceResult(ok: true, message: 'Resep telah dihapus.');
  }

  static Future<ServiceResult> setRecipeVerified(String id, bool verified) async {
    if (!isReady) return _notConfigured;
    try {
      await _recipes.doc(id).update({'verified': verified});
      return ServiceResult(ok: true,
          message: verified ? 'Resep terverifikasi.' : 'Verifikasi resep dicabut.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<Map<String, dynamic>?> fetchDraft(String uid) async {
    if (!isReady) return null;
    return (await _readDoc(_drafts.doc(uid))).data();
  }

  static Future<ServiceResult> saveDraft(String uid, Map<String, dynamic> data) async {
    // shortcut: satu draf teks per akun; buat daftar draf jika pengguna perlu beberapa.
    if (!isReady) return _notConfigured;
    if (uid != AuthService.firebaseUser?.uid || !AuthService.hasRealSession ||
        (data['title'] as String).trim().isEmpty ||
        (data['title'] as String).trim().length > 60) {
      return const ServiceResult(ok: false, message: 'Masukkan judul draf (maksimal 60 karakter).');
    }
    try {
      await _drafts.doc(uid).set({
        ...data, 'uid': uid, 'updatedAt': FieldValue.serverTimestamp(),
      });
      return const ServiceResult(ok: true, message: 'Draf tersimpan. Foto lokal tidak ikut tersimpan.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteDraft(String uid) async {
    if (!isReady) return _notConfigured;
    if (uid != AuthService.firebaseUser?.uid) {
      return const ServiceResult(ok: false, message: 'Masuk dengan akun pemilik draf.');
    }
    try {
      await _drafts.doc(uid).delete();
      return const ServiceResult(ok: true, message: 'Draf dihapus.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  // ───────────────────────── FAVORIT ─────────────────────────

  static String _favId(String uid, String recipeId) => '${uid}__$recipeId';

  static Future<Map<String, DateTime>> fetchFavoriteDates(String uid) async {
    if (!isReady) return const {};
    final snap = await _read(_favorites.where('uid', isEqualTo: uid));
    return {
      for (final doc in snap.docs)
        (doc.data()['recipeId'] ?? '') as String:
            (doc.data()['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0),
    };
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

  static Future<Set<String>> fetchLikedIds(String uid) async {
    if (!isReady) return const {};
    final snap = await _read(_likes.where('uid', isEqualTo: uid));
    return snap.docs.map((d) => d.data()['recipeId'] as String).toSet();
  }

  /// Like dan angka pada resep selalu diubah dalam satu transaksi.
  static Future<bool?> toggleLike(String uid, String recipeId) async {
    if (!isReady || uid != AuthService.firebaseUser?.uid ||
        !AuthService.hasRealSession) {
      return null;
    }
    try {
      return await _db.runTransaction<bool>((tx) async {
        final recipeRef = _recipes.doc(recipeId);
        final likeRef = _likes.doc(_favId(uid, recipeId));
        final recipe = await tx.get(recipeRef);
        final like = await tx.get(likeRef);
        final notificationRef = _notifications.doc('like-${_favId(uid, recipeId)}');
        final notification = await tx.get(notificationRef);
        if (!recipe.exists) throw StateError('Resep tidak ditemukan');
        final liked = !like.exists;
        final count = (recipe.data()?['likesCount'] as num?)?.toInt() ?? 0;
        tx.update(recipeRef, {'likesCount': count + (liked ? 1 : -1)});
        if (liked) {
          tx.set(likeRef, {
            'uid': uid, 'recipeId': recipeId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          final author = recipe.data()?['authorId'] as String?;
          if (author != null && author != uid && !notification.exists) {
            tx.set(notificationRef, {
              'recipientId': author, 'actorId': uid, 'recipeId': recipeId,
              'kind': 'like', 'title': recipe.data()?['title'],
              'seen': false, 'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } else {
          tx.delete(likeRef);
        }
        return liked;
      });
    } catch (_) {
      return null;
    }
  }

  /// Setiap akun dapat menandai satu recook untuk satu resep.
  static Future<ServiceResult> markRecook(String uid, String recipeId) async {
    if (!isReady || uid != AuthService.firebaseUser?.uid ||
        !AuthService.hasRealSession) {
      return const ServiceResult(ok: false, message: 'Masuk akun untuk menandai recook.');
    }
    try {
      return await _db.runTransaction<ServiceResult>((tx) async {
        final recipeRef = _recipes.doc(recipeId);
        final recookRef = _recooks.doc(_favId(uid, recipeId));
        final recipe = await tx.get(recipeRef);
        final existing = await tx.get(recookRef);
        if (!recipe.exists) {
          return const ServiceResult(ok: false, message: 'Resep sudah tidak tersedia.');
        }
        if (existing.exists) {
          return const ServiceResult(ok: false, message: 'Anda sudah menandai recook resep ini.');
        }
        final count = (recipe.data()?['recooksCount'] as num?)?.toInt() ?? 0;
        tx.update(recipeRef, {'recooksCount': count + 1});
        tx.set(recookRef, {
          'uid': uid, 'recipeId': recipeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        final author = recipe.data()?['authorId'] as String?;
        if (author != null && author != uid) {
          tx.set(_notifications.doc('recook-${_favId(uid, recipeId)}'), {
            'recipientId': author, 'actorId': uid, 'recipeId': recipeId,
            'kind': 'recook', 'title': recipe.data()?['title'],
            'seen': false, 'createdAt': FieldValue.serverTimestamp(),
          });
        }
        return const ServiceResult(ok: true, message: 'Recook berhasil dicatat.');
      });
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<List<Map<String, dynamic>>> fetchComments(String recipeId) async {
    if (!isReady) return const [];
    final snap = await _read(_recipes.doc(recipeId).collection('comments'));
    final docs = snap.docs.toList()..sort(_newestFirst);
    return [for (final doc in docs) {'id': doc.id, ...doc.data()}];
  }

  static Future<ServiceResult> addComment({
    required String uid, required String recipeId,
    required String text, required int rating,
  }) async {
    if (!isReady) return _notConfigured;
    if (uid != AuthService.firebaseUser?.uid || !AuthService.hasRealSession ||
        text.trim().isEmpty || text.trim().length > 500 || rating < 1 || rating > 5) {
      return const ServiceResult(ok: false, message: 'Ulasan tidak valid.');
    }
    try {
      final recipe = await _readDoc(_recipes.doc(recipeId));
      if (!recipe.exists) return const ServiceResult(ok: false, message: 'Resep tidak ditemukan.');
      final profile = await _readDoc(_users.doc(uid));
      if (!profile.exists) return const ServiceResult(ok: false, message: 'Profil tidak ditemukan.');
      // shortcut: satu ulasan per akun per resep agar rating tak bisa dispam.
      final comment = _recipes.doc(recipeId).collection('comments')
          .doc(_favId(uid, recipeId));
      final existing = await _readDoc(comment);
      if (existing.exists) {
        await comment.update({'text': text.trim(), 'rating': rating});
        return const ServiceResult(ok: true, message: 'Ulasan diperbarui.');
      }
      final notificationRef = _notifications.doc('comment-${comment.id}');
      final oldNotification = await _readDoc(notificationRef);
      final batch = _db.batch();
      batch.set(comment, {
        'authorId': uid, 'authorName': profile.data()!['name'], 'text': text.trim(),
        'rating': rating, 'createdAt': FieldValue.serverTimestamp(),
      });
      final author = recipe.data()?['authorId'] as String?;
      if (author != null && author != uid && !oldNotification.exists) {
        batch.set(notificationRef, {
          'recipientId': author, 'actorId': uid, 'recipeId': recipeId,
          'kind': 'comment', 'eventId': comment.id,
          'title': recipe.data()?['title'], 'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return const ServiceResult(ok: true, message: 'Ulasan terkirim.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteComment(String recipeId, String commentId) async {
    if (!isReady) return _notConfigured;
    try {
      await _recipes.doc(recipeId).collection('comments').doc(commentId).delete();
      return const ServiceResult(ok: true, message: 'Ulasan dihapus.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<bool?> toggleFollow(String uid, String authorId) async {
    if (!isReady || uid == authorId || authorId.isEmpty ||
        uid != AuthService.firebaseUser?.uid || !AuthService.hasRealSession) {
      return null;
    }
    try {
      final ref = _follows.doc(_favId(uid, authorId));
      final existing = await _readDoc(ref);
      if (existing.exists) {
        await ref.delete();
        return false;
      }
      await ref.set({
        'followerId': uid, 'followingId': authorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isFollowing(String uid, String authorId) async {
    if (!isReady || authorId.isEmpty) return false;
    return (await _readDoc(_follows.doc(_favId(uid, authorId)))).exists;
  }

  static Future<(int, int)> followCounts(String uid) async {
    if (!isReady) return (0, 0);
    final followers = await _read(_follows.where('followingId', isEqualTo: uid));
    final following = await _read(_follows.where('followerId', isEqualTo: uid));
    return (followers.size, following.size);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications(String uid) =>
      _notifications.where('recipientId', isEqualTo: uid).snapshots();

  static Future<void> markNotificationRead(String id) =>
      _notifications.doc(id).update({'seen': true});

  // ───────────────────────── LAPORAN ─────────────────────────

  static Map<String, dynamic> _reportToMap(
      DocumentSnapshot<Map<String, dynamic>> doc) {
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
    final snap = await _read(_reports);
    final docs = snap.docs.toList()..sort(_newestFirst);
    return docs.map(_reportToMap).toList();
  }

  static Future<ServiceResult> submitReport({
    required String reporterId,
    required String recipeId,
    required String recipeTitle,
    required String reason,
  }) async {
    if (!isReady) return _notConfigured;
    try {
      final profile = await _readDoc(_users.doc(reporterId));
      if (!profile.exists) {
        return const ServiceResult(ok: false, message: 'Profil pelapor tidak ditemukan.');
      }
      await _reports.add({
        'recipeId': recipeId,
        'recipeTitle': recipeTitle,
        'reporterId': reporterId,
        'reporterName': profile.data()!['name'],
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const ServiceResult(
        ok: true,
        message: 'Laporan terkirim. Terima kasih sudah menjaga komunitas.',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> resolveReport(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _reports.doc(id).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return const ServiceResult(
          ok: true, message: 'Laporan ditandai selesai.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> deleteReport(String id) async {
    if (!isReady) return _notConfigured;
    try {
      await _reports.doc(id).delete();
      return const ServiceResult(ok: true, message: 'Laporan dihapus.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  // ───────────────────────── PENGGUNA ─────────────────────────

  static Future<List<AppUser>> fetchUsers() async {
    if (!isReady) return const [];
    final snap = await _read(_users);
    final docs = snap.docs.toList()..sort(_newestFirst);
    return docs.map((d) => AppUser.fromFirestore(d.id, d.data())).toList();
  }

  /// Admin membuat "undangan" profil. Akun login-nya baru terbentuk saat
  /// pemilik email tersebut mendaftar lewat aplikasi. Profil pending hanya
  /// catatan admin; client pengguna tidak membaca/menghapus profil orang lain.
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
            'Catatan pending "$name" dibuat. Akun login harus didaftarkan secara terpisah.',
      );
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> setUserStatus(String uid, String status) async {
    if (!isReady) return _notConfigured;
    if (!const ['active', 'suspended', 'banned'].contains(status)) {
      return const ServiceResult(
          ok: false, message: 'Status pengguna tidak valid.');
    }
    if (uid == AuthService.firebaseUser?.uid) {
      return const ServiceResult(
          ok: false, message: 'Anda tidak bisa memoderasi akun sendiri.');
    }
    try {
      final profile = await _readDoc(_users.doc(uid));
      if (profile.data()?['pending'] == true) {
        return const ServiceResult(ok: false,
            message: 'Profil pending belum punya akun login untuk dimoderasi.');
      }
      await _users.doc(uid).update(
        {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
      );
      return const ServiceResult(
          ok: true, message: 'Status pengguna diperbarui.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> setUserRole(String uid, String role) async {
    if (!isReady) return _notConfigured;
    if (!const ['user', 'creator', 'admin'].contains(role) ||
        uid == AuthService.firebaseUser?.uid) {
      return const ServiceResult(ok: false, message: 'Role tidak valid atau akun sendiri.');
    }
    try {
      final profile = await _readDoc(_users.doc(uid));
      if (profile.data()?['pending'] == true) {
        return const ServiceResult(ok: false,
            message: 'Profil pending belum punya akun login. Ubah role sesudah pemilik mendaftar.');
      }
      await _users.doc(uid).update({'role': role, 'updatedAt': FieldValue.serverTimestamp()});
      return const ServiceResult(ok: true, message: 'Role pengguna diperbarui.');
    } catch (e) {
      return ServiceResult(ok: false, message: errorMessage(e));
    }
  }

  static Future<ServiceResult> banUser(String uid) =>
      setUserStatus(uid, 'banned');
}
