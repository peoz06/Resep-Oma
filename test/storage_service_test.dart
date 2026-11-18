import 'dart:typed_data';

import 'package:dapurkita/services/storage_service.dart';
import 'package:dapurkita/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mendeteksi JPEG, PNG, dan WebP berdasarkan isi berkas', () {
    expect(
        StorageService.imageContentType(Uint8List.fromList([0xff, 0xd8, 0xff])),
        'image/jpeg');
    expect(
        StorageService.imageContentType(Uint8List.fromList(
          [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
        )),
        'image/png');
    expect(
        StorageService.imageContentType(Uint8List.fromList(
          [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits],
        )),
        'image/webp');
  });

  test('Menolak file kosong, HEIC, GIF, dan file bukan gambar', () {
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList('GIF89a'.codeUnits),
      Uint8List.fromList([0, 0, 0, 24, ...'ftypheic'.codeUnits]),
      Uint8List.fromList('<script>alert(1)</script>'.codeUnits),
    ]) {
      expect(() => StorageService.imageContentType(bytes),
          throwsA(isA<ImageUploadException>()));
    }
  });

  test('Batas 5 MB diterima, satu byte di atasnya ditolak', () {
    final bytes = Uint8List(StorageService.maxImageBytes)
      ..setAll(0, [0xff, 0xd8, 0xff]);
    expect(StorageService.imageContentType(bytes), 'image/jpeg');
    expect(
      () => StorageService.imageContentType(
          Uint8List(StorageService.maxImageBytes + 1)),
      throwsA(isA<ImageUploadException>()
          .having((e) => e.message, 'message', contains('5 MB'))),
    );
  });

  test('Tanpa konfigurasi Supabase aplikasi tetap bisa berjalan', () async {
    await SupabaseService.init();
    expect(SupabaseService.isReady, isFalse);
    expect(SupabaseService.humanError, contains('SUPABASE_URL'));
  });
}
