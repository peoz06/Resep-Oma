import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

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
        accessToken: () async {
          final user = AuthService.firebaseUser;
          return user == null || user.isAnonymous ? null : user.getIdToken();
        },
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }
}
