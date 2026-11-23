import 'package:cloud_firestore/cloud_firestore.dart';

/// Profil pengguna yang disimpan di Firestore pada koleksi `users/{uid}`.
///
/// Role admin ditandai lewat field [role] (bukan custom claim).
class AppUser {
  final String uid;
  final String name;
  final String email;

  /// 'user' | 'admin'
  final String role;

  /// 'active' | 'suspended' | 'banned' (profil pending lama memakai 'baru').
  String status;

  final String? avatar;

  /// 'password' | 'google' | 'anonymous'
  final String provider;

  /// Label tampilan, contoh: `#USR-1042`.
  final String code;

  /// true bila profil ini dibuat admin lewat menu "Tambah Pengguna"
  /// dan pemiliknya belum pernah mendaftar dengan email tersebut.
  final bool pending;

  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
    this.status = 'active',
    this.avatar,
    this.provider = 'password',
    required this.code,
    this.pending = false,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isSuspended => status == 'suspended';
  bool get isActive => status == 'active';
  bool get isBanned => status == 'banned';
  String get accessDeniedMessage => isBanned
      ? 'Akun Anda diblokir oleh admin. Silakan hubungi admin.'
      : 'Akun Anda ditangguhkan atau belum aktif. Silakan hubungi admin.';
  bool get isPending => pending;

  /// Bahasa Indonesia untuk daftar admin.
  String get statusLabel {
    switch (status) {
      case 'suspended':
        return 'Ditangguhkan';
      case 'banned':
        return 'Diblokir';
      case 'baru':
        return 'Baru';
      case 'active':
        return 'Aktif';
      default:
        return 'Tidak aktif';
    }
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'creator':
        return 'Kreator';
      default:
        return 'Pengguna';
    }
  }

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final rawStatus = data.containsKey('status') ? data['status'] : 'active';
    String? text(String key) => data[key] is String ? data[key] as String : null;
    final createdAt = data['createdAt'];
    return AppUser(
      uid: uid,
      name: text('name') ?? '',
      email: text('email') ?? '',
      role: text('role') ?? 'user',
      status: rawStatus is String ? rawStatus : 'unknown',
      avatar: text('avatar'),
      provider: text('provider') ?? 'password',
      code: text('code') ?? AppUser.codeFromUid(uid),
      pending: data['pending'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// Bangun profil awal dari akun Firebase Auth (saat belum ada dokumen).
  factory AppUser.fromAuth(
    String uid, {
    required String name,
    required String email,
    String? avatar,
    String provider = 'password',
  }) {
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      avatar: avatar,
      provider: provider,
      code: AppUser.codeFromUid(uid),
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'avatar': avatar,
      'provider': provider,
      'code': code,
      'pending': pending,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? status,
    String? avatar,
    bool? pending,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      provider: provider,
      code: code,
      pending: pending ?? this.pending,
      createdAt: createdAt,
    );
  }

  /// Label ID stabil yang dibuat dari uid (dipakai bila dokumen belum punya `code`).
  static String codeFromUid(String uid) {
    var hash = 0;
    for (final ch in uid.codeUnits) {
      hash = (hash * 31 + ch) & 0x7fffffff;
    }
    final n = (hash % 9000) + 1000;
    return '#USR-$n';
  }

  static String generateCode() {
    final n = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
    return '#USR-$n';
  }
}
