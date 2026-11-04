import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Penangan inisialisasi Firebase.
///
/// Aplikasi tetap bisa dijalankan meski Firebase belum dikonfigurasi
/// (mis. sebelum menjalankan `flutterfire configure`). Saat [isReady] bernilai
/// false, semua layanan akan otomatis jatuh ke mode offline / data contoh.
class FirebaseService {
  static bool _ready = false;
  static String? _lastError;

  /// true bila `Firebase.initializeApp()` berhasil.
  static bool get isReady => _ready;

  /// Keterangan kegagalan terakhir (null bila tidak ada).
  static String? get lastError => _lastError;

  /// Panggil sekali saat aplikasi mulai. Aman dipanggil berulang.
  static Future<void> init() async {
    if (_ready) return;
    try {
      // Opsi diambil otomatis dari google-services.json (Android) /
      // GoogleService-Info.plist (iOS) yang dibuat oleh `flutterfire configure`.
      // Bila Anda ingin eksplisit, ganti menjadi:
      //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      //
      // Batas waktu dipasang agar aplikasi tidak tersangkut bila platform
      // host tidak merespons (mis. saat unit test / lingkungan tanpa plugin).
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 5));
      _ready = true;
      _lastError = null;
    } catch (e) {
      _ready = false;
      _lastError = e.toString();
    }
  }

  /// Pesan ramah untuk ditampilkan ke pengguna.
  static String get humanError {
    if (_ready) return '';
    final err = _lastError ?? '';
    if (err.contains('No Firebase App') || err.contains('default app')) {
      return 'Firebase belum dikonfigurasi. Jalankan `flutterfire configure` terlebih dahulu.';
    }
    if (err.contains('MissingPluginException')) {
      return 'Plugin Firebase belum terpasang di platform ini.';
    }
    return 'Firebase tidak tersedia di perangkat ini.';
  }
}
