import 'package:dapurkita/screens/admin_screens.dart';
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
}
