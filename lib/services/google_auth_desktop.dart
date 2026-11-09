import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

/// Hasil dari alur login Google di desktop.
class DesktopGoogleAuthResult {
  final String? idToken;

  /// Kode kesalahan: `timeout`, `access_denied`, `server_error`,
  /// `launch_failed`, `invalid_token`, dsb.
  final String? errorCode;
  final String? errorDescription;

  const DesktopGoogleAuthResult({
    this.idToken,
    this.errorCode,
    this.errorDescription,
  });

  bool get ok => idToken != null && idToken!.isNotEmpty;
}

/// Login Google untuk desktop (Windows/Linux).
///
/// Paket `google_sign_in` hanya menyediakan implementasi Android, iOS,
/// macOS, dan Web — tidak ada untuk Windows. Karena itu di desktop alurnya
/// dijalankan sendiri memakai OAuth 2.0 dengan *loopback redirect*:
///
/// 1. Server HTTP kecil listen di `http://127.0.0.1:<port>/callback`.
/// 2. Browser sistem dibuka ke halaman otorisasi Google.
/// 3. Google mengirim `id_token` (`response_type=id_token`, sehingga tidak
///    memerlukan `client_secret`) ke alamat loopback tadi.
/// 4. Halaman lokal meneruskan isi fragment ke server, server
///    mengembalikannya ke pemanggil lalu menutup diri.
class DesktopGoogleAuth {
  DesktopGoogleAuth._();

  /// Client ID OAuth milik aplikasi ini (tipe *Web application*).
  ///
  /// Di Google Cloud Console > Credentials, pastikan redirect URI
  /// `http://127.0.0.1` (loopback, port bebas) sudah terdaftar pada client
  /// ini, misalnya `http://127.0.0.1` atau `http://localhost`.
  static const String clientId =
      '581136907560-umfvnf7fekg18qtjhmuh07ie3st1nuci.apps.googleusercontent.com';

  static const Duration timeout = Duration(minutes: 3);

  /// Jalankan alur login Google dan kembalikan `id_token`-nya.
  static Future<DesktopGoogleAuthResult> signIn() async {
    HttpServer? server;
    Timer? timer;
    final completer = Completer<DesktopGoogleAuthResult>();

    void finish(DesktopGoogleAuthResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
    }

    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://127.0.0.1:$port/callback';
      final nonce = _randomNonce();

      server.listen((request) async {
        try {
          final uri = request.uri;
          if (uri.path != '/callback') {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
            return;
          }

          final idToken = uri.queryParameters['id_token'];
          final error = uri.queryParameters['error'];

          if (idToken == null && error == null) {
            // Fragment (#id_token=...) tidak dikirim ke server, jadi
            // halaman ini meneruskannya lewat query string.
            await _writeResponse(
              request.response,
              _bridgePage,
              contentType: 'text/html; charset=utf-8',
            );
            return;
          }

          if (error != null) {
            await _writeResponse(
              request.response,
              _resultPage(
                ok: false,
                message: error == 'access_denied'
                    ? 'Login Google dibatalkan.'
                    : 'Login Google gagal ($error).',
              ),
              contentType: 'text/html; charset=utf-8',
            );
            finish(DesktopGoogleAuthResult(
              errorCode: error,
              errorDescription: error == 'access_denied'
                  ? 'Login Google dibatalkan.'
                  : 'Google menolak permintaan login ($error).',
            ));
            return;
          }

          final verification = _verifyIdToken(idToken!, nonce);
          await _writeResponse(
            request.response,
            _resultPage(
              ok: verification == null,
              message: verification ??
                  'Login berhasil. Silakan kembali ke aplikasi Resep Oma.',
            ),
            contentType: 'text/html; charset=utf-8',
          );

          if (verification != null) {
            finish(DesktopGoogleAuthResult(
              errorCode: 'invalid_token',
              errorDescription: verification,
            ));
          } else {
            finish(DesktopGoogleAuthResult(idToken: idToken));
          }
        } catch (e) {
          finish(DesktopGoogleAuthResult(
            errorCode: 'server_error',
            errorDescription: 'Gagal memproses balasan Google: $e',
          ));
        }
      });

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'id_token',
        'scope': 'openid email profile',
        'nonce': nonce,
        'prompt': 'select_account',
      });

      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return const DesktopGoogleAuthResult(
          errorCode: 'launch_failed',
          errorDescription:
              'Tidak dapat membuka browser untuk login Google. Coba lagi.',
        );
      }

      timer = Timer(timeout, () {
        finish(const DesktopGoogleAuthResult(
          errorCode: 'timeout',
          errorDescription:
              'Waktu login Google habis atau jendela ditutup. Coba lagi.',
        ));
      });

      return await completer.future;
    } catch (e) {
      return DesktopGoogleAuthResult(
        errorCode: 'server_error',
        errorDescription: 'Login Google gagal: $e',
      );
    } finally {
      timer?.cancel();
      await server?.close(force: true);
    }
  }

  // ───────────────────────── INTERN ─────────────────────────

  static String _randomNonce() {
    final random = Random.secure();
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static Future<void> _writeResponse(
    HttpResponse response,
    String body, {
    required String contentType,
  }) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType.parse(contentType);
    response.write(body);
    await response.close();
  }

  /// `null` bila token valid, selain itu berisi pesan kesalahan.
  static String? _verifyIdToken(String idToken, String nonce) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return 'Token Google tidak lengkap.';
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final issuer = payload['iss']?.toString() ?? '';
      if (issuer != 'https://accounts.google.com' &&
          issuer != 'accounts.google.com') {
        return 'Token Google tidak berasal dari Google.';
      }
      if (payload['aud']?.toString() != clientId) {
        return 'Token Google ditujukan untuk aplikasi lain.';
      }
      if (payload['nonce']?.toString() != nonce) {
        return 'Token Google tidak cocok (nonce).';
      }

      final exp = payload['exp'];
      if (exp is int &&
          DateTime.fromMillisecondsSinceEpoch(exp * 1000)
              .isBefore(DateTime.now())) {
        return 'Token Google sudah kedaluwarsa.';
      }
      return null;
    } catch (e) {
      return 'Token Google tidak valid: $e';
    }
  }

  // ───────────────────────── HALAMAN BROWSER ─────────────────────────

  static const String _bridgePage = '''
<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<title>Login Google</title>
<style>
  body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
         text-align: center; padding-top: 72px; color: #1d1b20; background: #faf7fb; }
  .card { display: inline-block; background: #fff; padding: 28px 36px;
          border-radius: 20px; box-shadow: 0 8px 28px rgba(0,0,0,.08); }
  .spin { width: 34px; height: 34px; margin: 0 auto 14px;
          border: 4px solid #f3d7e0; border-top-color: #b01348;
          border-radius: 50%; animation: spin .9s linear infinite; }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>
</head>
<body>
  <div class="card">
    <div class="spin"></div>
    <p id="msg">Menyelesaikan login Google&hellip;</p>
  </div>
<script>
  var hash = location.hash ? location.hash.substring(1) : '';
  if (hash) {
    location.replace('/callback?' + hash);
  } else {
    document.getElementById('msg').textContent =
      'Tautan balik tidak lengkap. Silakan coba login lagi.';
  }
</script>
</body>
</html>
''';

  static String _resultPage({required bool ok, required String message}) {
    return '''
<!doctype html>
<html lang="id">
<head>
<meta charset="utf-8">
<title>${ok ? 'Login berhasil' : 'Login Google'}</title>
<style>
  body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
         text-align: center; padding-top: 72px; color: #1d1b20; background: #faf7fb; }
  .card { display: inline-block; background: #fff; padding: 28px 36px;
          border-radius: 20px; box-shadow: 0 8px 28px rgba(0,0,0,.08);
          max-width: 420px; }
  h1 { font-size: 20px; margin: 0 0 10px; color: ${ok ? '#b01348' : '#1d1b20'}; }
  p { font-size: 14px; line-height: 1.5; margin: 0; color: #5b5766; }
</style>
</head>
<body>
  <div class="card">
    <h1>${ok ? 'Login berhasil' : 'Login Google gagal'}</h1>
    <p>$message</p>
    <p style="margin-top:14px">Anda dapat menutup jendela ini.</p>
  </div>
</body>
</html>
''';
  }
}
