// Smoke test sederhana: memastikan aplikasi Resep Oma bisa dibangun
// dengan lapisan Firebase (Firebase belum dikonfigurasi di lingkungan test,
// jadi aplikasi berjalan dalam mode offline / data contoh).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:dapurkita/main.dart';
import 'package:dapurkita/screens/beranda_screen.dart';
import 'package:dapurkita/screens/favorit_screen.dart';
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

  testWidgets('Kartu rekomendasi dan filter bisa digeser dengan mouse',
      (tester) async {
    await tester.pumpWidget(const DapurKitaApp());
    await bootstrap(tester);

    final carousel = find.descendant(
      of: find.byType(BerandaScreen),
      matching: find.byWidgetPredicate((widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal),
    ).first;
    final position = tester.state<ScrollableState>(find.descendant(
      of: carousel, matching: find.byType(Scrollable),
    )).position;
    await tester.dragFrom(tester.getCenter(carousel), const Offset(-170, 0),
        kind: PointerDeviceKind.mouse);
    expect(position.pixels, greaterThan(0));
    await tester.dragFrom(tester.getCenter(carousel), const Offset(170, 0),
        kind: PointerDeviceKind.mouse);
    expect(position.pixels, 0);

    await tester.scrollUntilVisible(find.text('Categories'), 250,
        scrollable: find.descendant(of: find.byType(BerandaScreen),
            matching: find.byType(Scrollable)).first);
    await tester.drag(find.text('Categories'), const Offset(0, -120));
    await tester.pumpAndSettle();
    final categories = find.descendant(
      of: find.byType(BerandaScreen),
      matching: find.byWidgetPredicate((widget) => widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal),
    ).first;
    final categoryPosition = tester.state<ScrollableState>(find.descendant(
      of: categories, matching: find.byType(Scrollable),
    )).position;
    await tester.dragFrom(tester.getCenter(categories), const Offset(-170, 0),
        kind: PointerDeviceKind.mouse);
    expect(categoryPosition.pixels, greaterThan(0));
    await tester.dragFrom(tester.getCenter(categories), const Offset(170, 0),
        kind: PointerDeviceKind.mouse);
    expect(categoryPosition.pixels, 0);

    await tester.tap(find.text('Favorit').last);
    await tester.pumpAndSettle();
    final favoriteCategories = find.descendant(
      of: find.byType(FavoritScreen),
      matching: find.byWidgetPredicate((widget) => widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal),
    ).first;
    final favoritePosition = tester.state<ScrollableState>(find.descendant(
      of: favoriteCategories, matching: find.byType(Scrollable),
    )).position;
    await tester.dragFrom(tester.getCenter(favoriteCategories),
        const Offset(-170, 0), kind: PointerDeviceKind.mouse);
    expect(favoritePosition.pixels, greaterThan(0));
    await tester.dragFrom(tester.getCenter(favoriteCategories),
        const Offset(170, 0), kind: PointerDeviceKind.mouse);
    expect(favoritePosition.pixels, 0);
  });
}
