import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

/// Unggah berkas (foto resep & avatar) ke Firebase Storage.
class StorageService {
  static bool get isReady => FirebaseService.isReady;

  /// Unggah berkas hasil [ImagePicker] dan kembalikan URL unduhnya.
  /// Mengembalikan null bila Firebase tak tersedia atau unggah gagal.
  static Future<String?> uploadImage(
    XFile file, {
    required String folder,
    String? contentType,
  }) {
    return uploadFilePath(file.path, folder: folder, contentType: contentType);
  }

  /// Unggah berkas pada [path] (mis. hasil `image_picker`) ke Firebase Storage.
  static Future<String?> uploadFilePath(
    String path, {
    required String folder,
    String? contentType,
  }) async {
    if (!isReady) return null;
    if (path.isEmpty) return null;
    try {
      final safeName = path.split('/').last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final refPath = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final ref = FirebaseStorage.instance.ref(refPath);
      final snapshot = await ref.putFile(
        File(path),
        SettableMetadata(contentType: contentType ?? guessContentType(path)),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Tebak MIME type dari ekstensi berkas.
  static String guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  /// Pilih satu foto dari galeri / kamera.
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
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

  /// Pilih beberapa foto sekaligus (galeri).
  static Future<List<XFile>> pickMultiImage() async {
    try {
      return await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600);
    } catch (_) {
      return const [];
    }
  }
}
