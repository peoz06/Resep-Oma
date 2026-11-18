import 'package:dapurkita/models/recipe_model.dart';
import 'package:dapurkita/screens/profil_screen.dart';
import 'package:dapurkita/screens/unggah_resep_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recipe = MockData.getInitialRecipes().first.copyWith(
    title: 'Sup Ayam Buatan Sendiri',
    description: 'Resep keluarga yang sudah tersimpan.',
    category: 'Kategori Lama',
    time: '15 Menit',
    servings: '5 Porsi',
    difficulty: 'Mudah',
    image: '',
    secondaryImages: [],
    ingredients: [
      Ingredient(id: 'ayam', name: 'Ayam segar', amount: '500 gram')
    ],
    steps: [
      CookingStep(
          id: 'rebus', title: 'Rebus ayam', description: 'Rebus sampai matang.')
    ],
  );

  testWidgets('Tombol edit mengirim resep yang dipilih', (tester) async {
    Recipe? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ProfilScreen(
        recipes: [recipe],
        isLoggedIn: true,
        onSelectRecipe: (_) {},
        onDeleteRecipe: (_) {},
        onNavigateToUpload: () => fail('Edit tidak boleh membuka resep baru'),
        onEditRecipe: (value) => selected = value,
        onNavigateToFavorites: () {},
        onNavigateToAdmin: () {},
        onLogout: () {},
        onLogin: () {},
      )),
    ));
    await tester.scrollUntilVisible(find.byTooltip('Edit resep'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byTooltip('Edit resep'));
    expect(selected, same(recipe));
  });

  testWidgets('Form edit memuat data tersimpan dan tidak mengubah objek asli',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: UnggahResepScreen(
        recipe: recipe,
        userId: 'pemilik',
        onPublishRecipe: () {},
      )),
    ));

    final values = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text)
        .toList();
    expect(
        values,
        containsAll([
          recipe.title,
          recipe.description,
          recipe.time,
          recipe.servings,
          recipe.difficulty
        ]));
    expect(find.text('Kategori Lama'), findsOneWidget);
    expect(find.text('Salmon Mentai Rice Bowl Spesial'), findsNothing);

    await tester.scrollUntilVisible(find.byTooltip('Edit bahan'), 250,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.byTooltip('Edit bahan')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit bahan'));
    await tester.pumpAndSettle();
    final dialogFields = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(dialogFields.first).controller!.text,
        'Ayam segar');
    await tester.enterText(dialogFields.first, 'Ayam cincang');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Ayam cincang'), findsOneWidget);
    expect(recipe.ingredients.single.name, 'Ayam segar');

    await tester.scrollUntilVisible(find.byTooltip('Edit langkah'), 250,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(find.byTooltip('Edit langkah')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit langkah'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(dialogFields.first).controller!.text,
        'Rebus ayam');
    await tester.enterText(dialogFields.last, 'Rebus selama 20 menit.');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Rebus selama 20 menit.'), findsOneWidget);
    expect(recipe.steps.single.description, 'Rebus sampai matang.');

    await tester.scrollUntilVisible(find.text('Simpan Perubahan'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: UnggahResepScreen(
        key: const ValueKey('baru'),
        onPublishRecipe: () {},
      )),
    ));
    expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller?.text),
        contains('Salmon Mentai Rice Bowl Spesial'));
  });
}
