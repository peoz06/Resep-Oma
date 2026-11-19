import 'package:dapurkita/screens/admin_screens.dart';
import 'package:dapurkita/screens/profil_screen.dart';
import 'package:dapurkita/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Pengaturan admin memakai profil aktif dan membuka pengeditan profil',
      (tester) async {
    var editRequested = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: AdminSettingsScreen(
        userName: 'Admin Aktif',
        userEmail: 'admin-aktif@example.com',
        userAvatar: '',
        onEditProfile: () => editRequested = true,
        darkMode: false,
        onToggleDarkMode: (_) {},
        onLogoutAdmin: () {},
      )),
    ));
    expect(find.text('Admin Aktif'), findsOneWidget);
    expect(find.text('admin-aktif@example.com'), findsOneWidget);
    expect(find.text('admin@kuliner.app'), findsNothing);
    expect(tester.widget<AppCachedImage>(find.byType(AppCachedImage)).imageUrl,
        '');
    await tester.tap(find.byTooltip('Ubah foto profil'));
    expect(editRequested, isTrue);
    editRequested = false;
    await tester.tap(find.text('Ubah Kata Sandi di Profil'));
    expect(editRequested, isTrue);
  });

  test('URL Firebase lama tetap dikenali sebagai sumber gambar jaringan', () {
    expect(
        AppCachedImage.isNetworkSource(
            'https://firebasestorage.googleapis.com/v0/b/old/o/avatar.jpg?alt=media'),
        isTrue);
    expect(
        AppCachedImage.isNetworkSource(
            'https://example.supabase.co/storage/v1/object/public/avatars/uid/1.jpg'),
        isTrue);
  });

  testWidgets('Pengguna biasa tidak melihat akses admin dan punya form ubah kata sandi',
      (tester) async {
    String? message;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfilScreen(
      recipes: const [],
      isLoggedIn: true,
      onSelectRecipe: (_) {},
      onDeleteRecipe: (_) {},
      onNavigateToUpload: () {},
      onEditRecipe: (_) {},
      onNavigateToFavorites: () {},
      onNavigateToAdmin: () => fail('Pengguna biasa tidak boleh melihat tombol admin'),
      onLogout: () {},
      onLogin: () {},
      onShowToast: (text) => message = text,
    ))));
    expect(find.byIcon(Icons.settings), findsNothing);
    await tester.scrollUntilVisible(find.text('PENGATURAN AKUN'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Pengaturan Akun & Panel Admin'), findsNothing);
    await tester.scrollUntilVisible(find.text('Edit Profil'), -250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah Kata Sandi'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi lama'), findsOneWidget);
    expect(find.text('Kata sandi baru'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi baru'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Kata sandi baru'), 'rahasia123');
    await tester.enterText(find.widgetWithText(TextField, 'Konfirmasi kata sandi baru'), 'beda123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    expect(message, contains('tidak sesuai'));
  });

  testWidgets('Hanya admin melihat tombol panel admin', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfilScreen(
      recipes: const [],
      isLoggedIn: true,
      isAdmin: true,
      onSelectRecipe: (_) {},
      onDeleteRecipe: (_) {},
      onNavigateToUpload: () {},
      onEditRecipe: (_) {},
      onNavigateToFavorites: () {},
      onNavigateToAdmin: () {},
      onLogout: () {},
      onLogin: () {},
    ))));
    expect(find.byIcon(Icons.settings), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pengaturan Akun & Panel Admin'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Pengaturan Akun & Panel Admin'), findsOneWidget);
  });
}
