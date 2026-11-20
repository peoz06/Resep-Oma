import 'package:dapurkita/models/recipe_model.dart';
import 'package:dapurkita/screens/beranda_screen.dart';
import 'package:dapurkita/screens/eksplor_screen.dart';
import 'package:dapurkita/widgets/notifications_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tamu melihat resep Firestore di Beranda dan Eksplor',
      (tester) async {
    final recipe = Recipe.fromFirestore('resep-cloud', {
      'title': 'Resep Cloud',
      'authorName': 'Koki',
      'authorId': 'uid',
      'image': '',
      'category': 'Nusantara',
      'likesCount': 1,
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BerandaScreen(
      recipes: [recipe],
      userName: 'Tamu',
      onSelectRecipe: (_) {},
      onToggleFavorite: (_) {},
      onNavigateToExplore: () {},
    ))));
    expect(find.text('Resep Cloud'), findsWidgets);

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EksplorScreen(
      recipes: [recipe],
      onSelectRecipe: (_) {},
      onToggleFavorite: (_) {},
    ))));
    expect(find.text('1 Kategori'), findsOneWidget);
    expect(find.text('Nusantara'), findsWidgets);
  });

  test('Resep menyimpan identitas penulis, metrik, galeri, dan favorit', () {
    final date = DateTime(2026, 11, 20);
    final recipe = Recipe.fromFirestore(
        'r1',
        {
          'title': 'Sup',
          'authorId': 'uid1',
          'authorName': 'Oma',
          'likesCount': 12,
          'recooksCount': 10,
          'images': ['foto1', 'foto2'],
        },
        currentUid: 'uid1',
        isLiked: true,
        isFavorite: true,
        favoritedAt: date);
    expect(recipe.authorId, 'uid1');
    expect(recipe.isMyRecipe, isTrue);
    expect(recipe.isLiked, isTrue);
    expect(recipe.recooksCount, 10);
    expect(recipe.secondaryImages, ['foto1', 'foto2']);
    expect(recipe.copyWith(isFavorite: false).favoritedAt, isNull);
    expect(recipe.copyWith(isFavorite: true).favoritedAt, date);
    expect(MockData.getInitialRecipes().map((recipe) => recipe.recooksCount),
        everyElement(greaterThan(0)));
  });

  testWidgets('Kategori eksplor berasal dari resep, bukan angka hardcoded',
      (tester) async {
    final recipes = MockData.getInitialRecipes().take(3).toList();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EksplorScreen(
      recipes: recipes,
      onSelectRecipe: (_) {},
      onToggleFavorite: (_) {},
    ))));
    final categories = recipes.map((recipe) => recipe.category).toSet();
    expect(find.text('${categories.length} Kategori'), findsOneWidget);
    expect(find.text('84 resep'), findsNothing);
  });

  testWidgets('Notifikasi tamu tidak menampilkan aktivitas palsu',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: NotificationsSheet(),
    )));
    expect(find.text('Masuk akun untuk melihat aktivitas resep Anda.'),
        findsOneWidget);
    expect(find.textContaining('Chef Kenji'), findsNothing);
  });
}
