import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool _ready = false;

  static bool get isReady => _ready;
  static String get humanError =>
      'Supabase Storage belum siap. Periksa koneksi dan konfigurasi '
      'SUPABASE_URL serta SUPABASE_PUBLISHABLE_KEY saat menjalankan aplikasi.';

  static Future<void> init() async {
    if (_ready || _url.isEmpty || _key.isEmpty) return;
    try {
      await Supabase.initialize(
        url: _url,
        publishableKey: _key,
        debug: false,
        // Identitas tetap dikelola Firebase; Storage memakai akses anon tanpa sesi Supabase.
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
          persistSession: false,
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }
}
