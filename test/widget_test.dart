// Smoke test sederhana: memastikan aplikasi Resep Oma bisa dibangun
// dengan lapisan Firebase (Firebase belum dikonfigurasi di lingkungan test,
// jadi aplikasi berjalan dalam mode offline / data contoh).
import 'package:flutter_test/flutter_test.dart';

import 'package:dapurkita/main.dart';
import 'package:dapurkita/screens/main_navigation_screen.dart';

void main() {
  /// Majukan jam fake hingga bootstrap (inisialisasi Firebase + muat resep)
  /// selesai beserta toast mode-offline yang menyertainya.
  Future<void> bootstrap(WidgetTester tester) async {
    await tester.pump(); // frame pertama: layar pemuatan
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('Aplikasi Resep Oma bisa dibangun', (WidgetTester tester) async {
    await tester.pumpWidget(const DapurKitaApp());
    await bootstrap(tester);

    // Tidak ada exception saat membangun widget.
    expect(tester.takeException(), isNull);

    // Beranda harus sudah menampilkan data resep (mode demo/offline).
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
