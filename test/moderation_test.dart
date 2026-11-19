import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dapurkita/main.dart';
import 'package:dapurkita/models/recipe_model.dart';
import 'package:dapurkita/models/user_model.dart';
import 'package:dapurkita/screens/auth_screens.dart';
import 'package:dapurkita/screens/beranda_screen.dart';
import 'package:dapurkita/services/recipe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login mulai kosong dan Ingat Saya tidak tercentang',
      (tester) async {
    String? message;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LoginScreen(
          onLoginSuccess: (_) {},
          onNavigateToRegister: () {},
          onShowToast: (text) => message = text,
        ),
      ),
    ));
    expect(tester.widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text), everyElement(isEmpty));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('Masuk Sekarang'));
    expect(message, contains('email'));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  test('Status akun lama, suspended, banned, dan tidak valid dibedakan', () {
    expect(AppUser.fromFirestore('legacy', {}).isActive, isTrue);
    for (final status in ['suspended', 'banned', 'baru', '', null]) {
      final user = AppUser.fromFirestore('uid', {'status': status});
      expect(user.isActive, isFalse);
      expect(user.accessDeniedMessage, isNotEmpty);
      expect(user.statusLabel, isNot('Aktif'));
    }
    final banned = AppUser.fromFirestore('uid', {'status': 'banned'});
    expect(banned.isBanned, isTrue);
    expect(banned.statusLabel, 'Diblokir');
    expect(AdminUser.fromAppUser(banned).status, 'Diblokir');
  });

  test('Error permission-denied tidak ditampilkan mentah', () {
    final message = RecipeService.errorMessage(FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'RAW FIRESTORE ERROR',
    ));
    expect(message, contains('izin'));
    expect(message, isNot(contains('RAW FIRESTORE ERROR')));
    expect(message, isNot(contains('permission-denied')));
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(const DapurKitaApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> chooseLogin(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(find.text('Masuk Akun Diperlukan'), findsOneWidget);
    await tester.ensureVisible(find.text('Sudah Punya Akun? Masuk'));
    await tester.tap(find.text('Sudah Punya Akun? Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  testWidgets('Tamu menyimpan favorit diarahkan ke login, bukan toggle lokal',
      (tester) async {
    await openApp(tester);
    tester
        .widget<BerandaScreen>(find.byType(BerandaScreen))
        .onToggleFavorite('nasi-lemak');
    await chooseLogin(tester);
  });

  testWidgets('Tamu mengunggah resep diarahkan ke login', (tester) async {
    await openApp(tester);
    await tester.tap(find.byIcon(Icons.add));
    await chooseLogin(tester);
  });
}
