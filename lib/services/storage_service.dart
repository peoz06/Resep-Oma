import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

class ImageUploadException implements Exception {
  final String message;
  const ImageUploadException(this.message);
  @override
  String toString() => message;
}

/// Unggah foto ke Supabase memakai sesi Firebase.
/// File tidak dihapus otomatis karena Storage dan Firestore tidak berbagi transaksi.
class StorageService {
  static bool get isReady => SupabaseService.isReady;
  static const maxImageBytes = 5 * 1024 * 1024;

  /// Periksa isi berkas, bukan hanya ekstensi atau MIME dari perangkat.
  static String imageContentType(Uint8List bytes) {
    if (bytes.length > maxImageBytes) {
      throw const ImageUploadException('Ukuran foto maksimal 5 MB.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    throw const ImageUploadException(
      'Foto harus berformat JPEG, PNG, atau WebP. Konversikan foto HEIC/GIF terlebih dahulu.',
    );
  }

  static Future<String> uploadImage(
    XFile file, {
    required String bucket,
    required String uid,
  }) async {
    if (!isReady) throw ImageUploadException(SupabaseService.humanError);
    if (!AuthService.hasRealSession ||
        AuthService.firebaseUser?.uid != uid ||
        uid.isEmpty ||
        uid == '.' ||
        uid == '..' ||
        uid.contains(RegExp(r'[/\\]'))) {
      throw const ImageUploadException(
          'Identitas pengguna tidak valid. Silakan masuk kembali.');
    }
    try {
      if (await file.length() > maxImageBytes) {
        throw const ImageUploadException('Ukuran foto maksimal 5 MB.');
      }
      // Bytes mendukung file picker web dan native tanpa bergantung pada dart:io.
      final bytes = await file.readAsBytes();
      final contentType = imageContentType(bytes);
      final extension =
          contentType == 'image/jpeg' ? 'jpg' : contentType.split('/').last;
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$extension';
      final storage = Supabase.instance.client.storage.from(bucket);
      // Tanpa upsert, benturan path ditolak alih-alih menimpa foto yang sudah ada.
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
      return storage.getPublicUrl(path);
    } on ImageUploadException {
      rethrow;
    } on StorageException catch (e) {
      throw ImageUploadException('Upload foto ke Supabase gagal: ${e.message}');
    } catch (_) {
      throw const ImageUploadException(
          'Gagal membaca atau mengunggah foto. Periksa file dan koneksi internet.');
    }
  }

  /// Pilih satu foto dari galeri / kamera.
  static Future<XFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      return await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      return null;
    }
  }
}
