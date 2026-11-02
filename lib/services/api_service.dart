import 'dart:convert';
import 'package:http/http.dart' as http;

/// Koneksi ke API PHP di XAMPP.
/// - `localhost` dipakai saat app jalan di emulator / desktop.
/// - `localNetwork` dipakai saat jalan di HP asli (satu WiFi dengan laptop).
/// - URL dipilih otomatis saat aplikasi pertama kali dibuka.
class ApiService {
  static const String localhost = 'http://localhost/api_resepoma';
  static const String localNetwork = 'http://192.168.18.6/api_resepoma';
  static const String emulatorAndroid = 'http://10.0.2.2/api_resepoma';

  // Baseline, akan ditentukan otomatis oleh resolveBaseUrl().
  static String _baseUrl = localhost;
  static String get baseUrl => _baseUrl;
  static bool _resolved = false;
  static bool _available = false; // false = tidak ada URL yang merespons

  /// Coba kandidat URL satu per satu, pakai yang pertama merespons.
  /// Hasilnya di-cache sehingga hanya dilakukan sekali per aplikasi.
  static Future<void> resolveBaseUrl() async {
    if (_resolved) return;
    for (final candidate in [localhost, emulatorAndroid, localNetwork]) {
      try {
        final res = await http
            .get(Uri.parse('$candidate/recipes.php'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _baseUrl = candidate;
          _resolved = true;
          _available = true;
          return;
        }
      } catch (_) {
        // Lanjut kandidat berikutnya.
      }
    }
    _resolved = true; // Gagal semua: tidak akan dicoba lagi di sesi ini.
  }

  /// true kalau ada server API yang merespons.
  static bool get isServerAvailable => _available;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path}/$path',
      queryParameters: query,
    );
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    body['__statusCode'] = res.statusCode;
    return body;
  }

  // ───────────────────────── AUTH ─────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            _uri('register.php'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server. Pastikan XAMPP berjalan dan HP/laptop satu WiFi.',
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            _uri('login.php'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server. Pastikan XAMPP berjalan dan HP/laptop satu WiFi.',
        '__statusCode': 0,
      };
    }
  }

  // ───────────────────────── RECIPES ─────────────────────────

  static Future<Map<String, dynamic>> fetchRecipes({int? userId}) async {
    try {
      final query = userId != null ? {'user_id': '$userId'} : null;
      final res = await http
          .get(_uri('recipes.php', query))
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Gagal memuat resep dari server.',
        'recipes': [],
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> fetchRecipeDetail(int id) async {
    try {
      final res = await http
          .get(_uri('recipes.php', {'id': '$id'}))
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Gagal memuat detail resep.',
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> createRecipe({
    required int userId,
    required String title,
    required String description,
    required String category,
    required String cookTime,
    required String servings,
    required String difficulty,
    required String image,
    required List<Map<String, String>> ingredients,
    required List<Map<String, String>> steps,
  }) async {
    try {
      final res = await http
          .post(
            _uri('create_recipe.php'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'description': description,
              'category': category,
              'cook_time': cookTime,
              'servings': servings,
              'difficulty': difficulty,
              'image': image,
              'ingredients': ingredients,
              'steps': steps,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server saat menyimpan resep.',
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> deleteRecipe(int id) async {
    try {
      final res = await http
          .post(
            _uri('delete_recipe.php'),
            headers: _headers,
            body: jsonEncode({'id': id}),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server saat menghapus resep.',
        '__statusCode': 0,
      };
    }
  }

  // ───────────────────────── FAVORITES ─────────────────────────

  static Future<Map<String, dynamic>> fetchFavorites(int userId) async {
    try {
      final res = await http
          .get(_uri('favorites.php', {'user_id': '$userId'}))
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Gagal memuat favorit.',
        'favorites': [],
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> toggleFavorite({
    required int userId,
    required int recipeId,
  }) async {
    try {
      final res = await http
          .post(
            _uri('favorites.php'),
            headers: _headers,
            body: jsonEncode({'user_id': userId, 'recipe_id': recipeId}),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server.',
        '__statusCode': 0,
      };
    }
  }

  // ───────────────────────── USERS ─────────────────────────

  static Future<Map<String, dynamic>> fetchUsers() async {
    try {
      final res = await http
          .get(_uri('users.php'))
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Gagal memuat daftar user.',
        'users': [],
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserAction({
    required int id,
    required String action,
    String? name,
    String? email,
  }) async {
    try {
      final res = await http
          .post(
            _uri('users.php'),
            headers: _headers,
            body: jsonEncode({
              'id': id,
              'action': action,
              if (name != null) 'name': name,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server.',
        '__statusCode': 0,
      };
    }
  }

  // ───────────────────────── REPORTS (Laporan Resep) ─────────────────────────

  static Future<Map<String, dynamic>> fetchReports({int? recipeId}) async {
    try {
      final query = recipeId != null ? {'recipe_id': '$recipeId'} : null;
      final res = await http
          .get(_uri('reports.php', query))
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Gagal memuat laporan.',
        'reports': [],
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> submitReport({
    required int userId,
    required int recipeId,
    required String reason,
  }) async {
    try {
      final res = await http
          .post(
            _uri('reports.php'),
            headers: _headers,
            body: jsonEncode({
              'user_id': userId,
              'recipe_id': recipeId,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server.',
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> resolveReport(int id) async {
    try {
      final res = await http
          .post(
            _uri('reports.php'),
            headers: _headers,
            body: jsonEncode({'id': id, 'action': 'resolve'}),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server.',
        '__statusCode': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> deleteReport(int id) async {
    try {
      final res = await http
          .post(
            _uri('reports.php'),
            headers: _headers,
            body: jsonEncode({'id': id, 'action': 'delete'}),
          )
          .timeout(const Duration(seconds: 10));
      return await _handle(res);
    } catch (e) {
      return {
        'status': false,
        'message': 'Tidak dapat terhubung ke server.',
        '__statusCode': 0,
      };
    }
  }
}
