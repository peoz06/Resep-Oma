// Smoke test sederhana: memastikan aplikasi Resep Oma bisa dibangun.
import 'package:flutter_test/flutter_test.dart';

import 'package:dapurkita/main.dart';

void main() {
  testWidgets('Aplikasi Resep Oma bisa dibangun', (WidgetTester tester) async {
    await tester.pumpWidget(const DapurKitaApp());
    await tester.pump();
    // Tidak ada exception saat membangun widget awal.
    expect(tester.takeException(), isNull);
  });
}
