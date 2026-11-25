// Codec transport SDK dipakai agar tes tetap offline tanpa paket mock tambahan.
// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/pigeon/messages.pigeon.dart' as fs;
import 'package:dapurkita/models/recipe_model.dart';
import 'package:dapurkita/screens/admin_screens.dart';
import 'package:dapurkita/screens/auth_screens.dart';
import 'package:dapurkita/screens/beranda_screen.dart';
import 'package:dapurkita/screens/eksplor_screen.dart';
import 'package:dapurkita/screens/main_navigation_screen.dart';
import 'package:dapurkita/screens/profil_screen.dart';
import 'package:dapurkita/screens/unggah_resep_screen.dart';
import 'package:dapurkita/services/auth_service.dart';
import 'package:dapurkita/services/firebase_service.dart';
import 'package:dapurkita/services/recipe_service.dart';
import 'package:dapurkita/theme/app_theme.dart';
import 'package:dapurkita/widgets/app_cached_image.dart';
import 'package:dapurkita/widgets/notifications_sheet.dart';
import 'package:dapurkita/widgets/recipe_detail_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/pigeon/messages.pigeon.dart' as auth;
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FirestoreCodec extends fs.PigeonCodec {
  const _FirestoreCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    // Decoder SDK tidak membaca balik FieldPath/sentinel yang hanya dikirim ke native.
    if (type == 192) {
      return List.generate(readSize(buffer), (_) => readValue(buffer)).join('.');
    }
    if (type == 187) return 'serverTimestamp';
    return super.readValueOfType(type, buffer);
  }
}

class _CoreMock extends MockFirebaseApp {
  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [];

  @override
  Future<CoreInitializeResponse> initializeApp(
      String name, CoreFirebaseOptions options) async =>
      CoreInitializeResponse(name: name, options: options, pluginConstants: {});
}

void _host(String method, FutureOr<Object?> Function(List<Object?>) reply, {
  String api = 'cloud_firestore_platform_interface.FirebaseFirestoreHostApi',
  MessageCodec<Object?> codec = const _FirestoreCodec(),
}) {
  final channel = BasicMessageChannel<Object?>('dev.flutter.pigeon.$api.$method', codec);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(channel, (message) async {
    try {
      return [await reply(message! as List<Object?>)];
    } on PlatformException catch (e) {
      return [e.code, e.message, e.details];
    }
  });
}

void _authHost(String method, FutureOr<Object?> Function(List<Object?>) reply,
    {bool user = false}) => _host(method, reply,
      api: 'firebase_auth_platform_interface.FirebaseAuth${user ? 'User' : ''}HostApi',
      codec: auth.FirebaseAuthHostApi.pigeonChannelCodec);

final _metadata = fs.InternalSnapshotMetadata(hasPendingWrites: false, isFromCache: false);
fs.InternalDocumentSnapshot _doc(String path, Map<String, dynamic>? data) =>
    fs.InternalDocumentSnapshot(path: path, data: data, metadata: _metadata);
fs.InternalQuerySnapshot _query([List<fs.InternalDocumentSnapshot> docs = const []]) =>
    fs.InternalQuerySnapshot(documents: docs, documentChanges: [], metadata: _metadata);

void _draftTransaction(
  fs.InternalDocumentSnapshot Function() read,
  FutureOr<void> Function(List<fs.InternalTransactionCommand>) commit,
) {
  const id = 'audit-draft';
  const channel = MethodChannel(
    'plugins.flutter.io/firebase_firestore/transaction/$id',
    StandardMethodCodec(fs.PigeonCodec()),
  );
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  void emit(Map<String, Object?> event) {
    unawaited(messenger.handlePlatformMessage(
      channel.name, channel.codec.encodeSuccessEnvelope(event), (_) {},
    ));
  }

  messenger.setMockMessageHandler(channel.name, (message) async {
    final method = const StandardMessageCodec().readValue(ReadBuffer(message!));
    if (method == 'listen') {
      emit({'appName': '[DEFAULT]'});
    }
    return channel.codec.encodeSuccessEnvelope(null);
  });
  _host('transactionCreate', (_) => id);
  _host('transactionGet', (args) {
    expect(args[2], 'drafts/owner');
    return read();
  });
  _host('transactionStoreResult', (args) async {
    await commit((args[2]! as List).cast<fs.InternalTransactionCommand>());
    emit({'complete': true});
    return null;
  });
}

Future<void> _openDraftForPublish(WidgetTester tester, VoidCallback onPublish) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/image_picker'),
          (_) async => 'https://example.com/photo.jpg');
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: UnggahResepScreen(
    userId: 'owner', onPublishRecipe: onPublish,
  ))));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(AppCachedImage).first);
  Navigator.of(tester.element(find.byType(UnggahResepScreen))).pop(ImageSource.gallery);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Terbitkan Resep Sekarang'), 300,
      scrollable: find.byType(Scrollable).first);
}

auth.InternalUserDetails _firebaseUser([String name = 'Oma']) =>
    auth.InternalUserDetails(
      userInfo: auth.InternalUserInfo(uid: 'owner', email: 'oma@example.com',
          displayName: name, isAnonymous: false, isEmailVerified: true),
      providerData: [],
    );

final _profile = <String, dynamic>{
  'name': 'Oma', 'email': 'oma@example.com', 'role': 'user', 'status': 'active',
};
final _recipe = <String, dynamic>{
  'title': 'Sup Ayam', 'authorId': 'owner', 'authorName': 'Oma',
  'description': 'Resep keluarga', 'category': 'Nusantara', 'image': '',
  'cookTime': '15 menit', 'servings': '2 porsi', 'difficulty': 'Mudah',
  'ingredients': [{'name': 'Ayam', 'amount': '500 g'}],
  'steps': [{'title': 'Rebus', 'description': 'Rebus hingga matang'}],
  'likesCount': 0, 'recooksCount': 0, 'verified': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestFirebaseCoreHostApi.setUp(_CoreMock());
    await FirebaseService.init();
    expect(FirebaseService.isReady, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => debugDefaultTargetPlatformOverride = null);

  setUp(() async {
    final user = _firebaseUser();
    for (final method in ['createUserWithEmailAndPassword', 'signInWithEmailAndPassword']) {
      _authHost(method, (_) => auth.InternalUserCredential(user: user));
    }
    _authHost('updateProfile', (_) => user, user: true);
    _authHost('delete', (_) => null, user: true);
    _authHost('signOut', (_) => null);
    await FirebaseAuth.instance.signOut();
    _host('documentReferenceGet', (args) {
      final path = (args[1]! as fs.DocumentReferenceRequest).path;
      return _doc(path, path.startsWith('users/') ? _profile
          : path.startsWith('recipes/') ? _recipe : null);
    });
    _host('documentReferenceSet', (_) => null);
    _host('documentReferenceDelete', (_) => null);
    _host('queryGet', (args) => _query(args[1] == 'recipes'
        ? [_doc('recipes/r1', _recipe)] : []));
    _host('querySnapshot', (_) => 'audit-query');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(
          'plugins.flutter.io/firebase_firestore/query/audit-query',
          StandardMethodCodec(fs.PigeonCodec()),
        ), (_) async => null);
  });

  testWidgets('Timeout profil tidak menghapus akun; login berikutnya memulihkan profil', (tester) async {
    final write = Completer<void>();
    var deletes = 0;
    _host('documentReferenceSet', (_) => write.future);
    _authHost('delete', (_) { deletes++; return null; }, user: true);
    AuthResult? result;
    AuthService.register(name: 'Oma', email: 'oma@example.com', password: 'secret123')
        .then((value) => result = value);
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(result?.ok, isFalse);
    expect(result?.message, contains('tidak perlu mendaftar ulang'));
    expect(deletes, 0);
    expect(FirebaseAuth.instance.currentUser, isNull);
    write.complete();
    await tester.pump();
    expect(deletes, 0);
    final recovered = await AuthService.signInWithEmail(email: 'oma@example.com', password: 'secret123');
    expect(recovered.ok, isTrue);
    expect(recovered.user?.name, 'Oma');
  });

  test('Penolakan profil yang pasti tetap membersihkan akun baru', () async {
    var deletes = 0;
    _host('documentReferenceSet', (_) => throw PlatformException(code: 'permission-denied'));
    _authHost('delete', (_) { deletes++; return null; }, user: true);
    final result = await AuthService.register(name: 'Oma', email: 'oma@example.com', password: 'secret123');
    expect(result.ok, isFalse);
    expect(deletes, 1);
  });

  testWidgets('Login tertunda tidak dapat ditinggalkan ke layar tamu atau daftar', (tester) async {
    final response = Completer<auth.InternalUserCredential>();
    _authHost('signInWithEmailAndPassword', (_) => response.future);
    var leftScreen = false;
    var loggedIn = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StatefulBuilder(builder: (context, update) => leftScreen
          ? const Text('Layar lain')
          : LoginScreen(
              onLoginSuccess: (_) => loggedIn = true,
              onBackToGuest: () => update(() => leftScreen = true),
              onNavigateToRegister: () => update(() => leftScreen = true),
            )),
    )));
    await tester.enterText(find.byType(TextField).first, 'oma@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.ensureVisible(find.text('Masuk Sekarang'));
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pump();
    final register = find.widgetWithText(TextButton, 'Daftar Sekarang');
    final canRegister = tester.widget<TextButton>(register).onPressed != null;
    await tester.ensureVisible(find.text('Lanjut sebagai Tamu'));
    await tester.tap(find.text('Lanjut sebagai Tamu'));
    await tester.pump();
    response.complete(auth.InternalUserCredential(user: _firebaseUser()));
    await tester.pumpAndSettle();
    expect(canRegister, isFalse);
    expect(leftScreen, isFalse);
    expect(loggedIn, isTrue);
  });

  test('Simpan ulang nama yang sama memperbaiki profil dan resep lama', () async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'oma@example.com', password: 'secret123',
    );
    _authHost('updateProfile', (_) => _firebaseUser('Oma Baru'), user: true);
    final profile = {..._profile};
    var authorName = 'Oma';
    var profileAttempts = 0;
    var batchAttempts = 0;
    _host('documentReferenceGet', (_) => _doc('users/owner', profile));
    _host('documentReferenceSet', (args) {
      if (++profileAttempts == 1) throw PlatformException(code: 'unavailable');
      final request = args[1]! as fs.DocumentReferenceRequest;
      profile['name'] = request.data!['name'];
      return null;
    });
    _host('queryGet', (_) => _query([
      _doc('recipes/r1', {..._recipe, 'authorName': authorName}),
    ]));
    _host('writeBatchCommit', (args) {
      if (++batchAttempts == 1) throw PlatformException(code: 'unavailable');
      final command = (args[1]! as List).single as fs.InternalTransactionCommand;
      authorName = command.data!['authorName'] as String;
      return null;
    });

    expect((await AuthService.updateProfile(name: 'Oma Baru')).ok, isFalse);
    expect(FirebaseAuth.instance.currentUser?.displayName, 'Oma Baru');
    final partial = await AuthService.updateProfile(name: 'Oma Baru');
    expect(partial.user?.name, 'Oma Baru');
    expect(partial.message, contains('resep lama'));
    expect(authorName, 'Oma');

    expect((await AuthService.updateProfile(name: 'Oma Baru')).ok, isTrue);
    expect(authorName, 'Oma Baru');
    expect(batchAttempts, 2);
  });

  testWidgets('Draf terlambat tidak menimpa deskripsi baru meski judul kosong', (tester) async {
    final draft = Completer<fs.InternalDocumentSnapshot>();
    _host('documentReferenceGet', (_) => draft.future);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: UnggahResepScreen(
      userId: 'owner', onPublishRecipe: () {},
    ))));
    await tester.enterText(find.byType(TextField).at(1), 'Isian baru');
    draft.complete(_doc('drafts/owner', {..._recipe, 'title': 'Draf lama'}));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, 'Isian baru');
  });

  testWidgets('Terbit terkunci sampai penghapusan draf selesai', (tester) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: 'oma@example.com', password: 'secret123');
    final deletion = Completer<void>();
    var writes = 0;
    var published = 0;
    final draft = _doc('drafts/owner', {..._recipe, 'updatedAt': Timestamp(1, 0)});
    _host('documentReferenceGet', (args) {
      final path = (args[1]! as fs.DocumentReferenceRequest).path;
      return path == 'drafts/owner' ? draft : _doc(path, _profile);
    });
    _host('documentReferenceSet', (_) { writes++; return null; });
    _draftTransaction(() => draft, (commands) {
      expect(commands.single.path, 'drafts/owner');
      return deletion.future;
    });
    await _openDraftForPublish(tester, () => published++);
    await tester.tap(find.text('Terbitkan Resep Sekarang'));
    await tester.pump();
    final publishButton = find.byType(ElevatedButton).last;
    expect(tester.widget<ElevatedButton>(publishButton).onPressed, isNull);
    expect(writes, 1);
    expect(published, 0);
    await tester.tap(publishButton, warnIfMissed: false);
    await tester.pump();
    expect(writes, 1);
    deletion.complete();
    await tester.pumpAndSettle();
    expect(published, 1);
  });

  testWidgets('Terbit tidak menghapus versi draf yang baru disimpan perangkat lain', (tester) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'oma@example.com', password: 'secret123',
    );
    Map<String, dynamic>? draft = {
      ..._recipe, 'updatedAt': Timestamp(1, 0), 'revision': 'versi-asli',
    };
    _host('documentReferenceGet', (args) {
      final path = (args[1]! as fs.DocumentReferenceRequest).path;
      return _doc(path, path == 'drafts/owner' ? draft : _profile);
    });
    _host('documentReferenceDelete', (_) { draft = null; return null; });
    _draftTransaction(() => _doc('drafts/owner', draft), (commands) {
      if (commands.isNotEmpty) draft = null;
    });

    var published = 0;
    await _openDraftForPublish(tester, () => published++);
    draft = {...draft!, 'title': 'Draf baru', 'updatedAt': Timestamp(2, 0),
      'revision': 'versi-baru'};
    await tester.tap(find.text('Terbitkan Resep Sekarang'));
    await tester.pumpAndSettle();
    expect(published, 1);
    expect(draft?['title'], 'Draf baru');
  });

  test('Setiap simpan draf mengembalikan revisi yang ditulisnya', () async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'oma@example.com', password: 'secret123',
    );
    final revisions = <Object?>[];
    _host('documentReferenceSet', (args) {
      final request = args[1]! as fs.DocumentReferenceRequest;
      expect(request.path, 'drafts/owner');
      revisions.add(request.data!['revision']);
      return null;
    });
    for (var i = 0; i < 2; i++) {
      final saved = await RecipeService.saveDraft('owner', {'title': 'Judul sama'});
      expect(saved.result.ok, isTrue);
      expect(saved.revision, isNotEmpty);
      expect(saved.revision, revisions.last);
    }
    expect(revisions.toSet(), hasLength(2));
  });

  testWidgets('Pembaruan sosial membaca satu resep tanpa mereset pencarian dan scroll', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme(), home: MainNavigationScreen(
      darkMode: false, onToggleDarkMode: (_) {},
    )));
    await tester.pumpAndSettle();
    tester.widget<BerandaScreen>(find.byType(BerandaScreen)).onNavigateToExplore();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sup');
    final search = tester.widget<TextField>(find.byType(TextField)).controller!;
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(EksplorScreen));
    final verticalScroll = find.byWidgetPredicate((widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down);
    final scroll = tester.state<ScrollableState>(verticalScroll.first).position;
    scroll.jumpTo(scroll.maxScrollExtent.clamp(0, 100));
    final screen = tester.widget<EksplorScreen>(find.byType(EksplorScreen));
    screen.onSelectRecipe(screen.recipes.single);
    await tester.pumpAndSettle();
    final detail = tester.widget<RecipeDetailSheet>(find.byType(RecipeDetailSheet));
    final offset = scroll.pixels;
    var reads = 0;
    _host('documentReferenceGet', (args) {
      final request = args[1]! as fs.DocumentReferenceRequest;
      expect(request.path, 'recipes/r1');
      reads++;
      return _doc(request.path, {..._recipe, 'likesCount': 1, 'recooksCount': 1});
    });
    _host('queryGet', (_) => fail('Pembaruan sosial tidak boleh membaca seluruh katalog'));
    detail.recipe.isLiked = true;
    detail.onRecipeChanged!();
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(tester.state(find.byType(EksplorScreen)), same(state));
    final updated = tester.widget<EksplorScreen>(find.byType(EksplorScreen)).recipes.single;
    expect(updated.likesCount, 1);
    expect(updated.recooksCount, 1);
    expect(updated.isLiked, isTrue);
    expect(search.text, 'Sup');
    expect(scroll.pixels, offset);
  });

  testWidgets('Katalog menambah halaman meski dokumen terakhir halaman pertama rusak', (tester) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final time = Timestamp.fromDate(DateTime(2026, 11, 20));
    var queries = 0;
    _host('queryGet', (args) {
      expect(args[1], 'recipes');
      final params = args[3]! as fs.InternalQueryParameters;
      expect(params.limit, 25);
      expect(params.orderBy!.first, ['createdAt', true]);
      if (++queries == 1) {
        expect(params.startAfter, isNull);
        return _query([
          for (var i = 0; i < 24; i++)
            _doc('recipes/r$i', {..._recipe, 'createdAt': time}),
          _doc('recipes/rusak', {..._recipe, 'createdAt': time, 'ingredients': [42]}),
        ]);
      }
      expect(params.startAfter, [time, 'rusak']);
      return _query([_doc('recipes/halaman-2', {
        ..._recipe, 'title': 'Opor halaman kedua', 'createdAt': time,
      })]);
    });
    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme(), home: MainNavigationScreen(
      darkMode: false, onToggleDarkMode: (_) {},
    )));
    await tester.pumpAndSettle();
    tester.widget<BerandaScreen>(find.byType(BerandaScreen)).onNavigateToExplore();
    await tester.pumpAndSettle();
    expect(tester.widget<EksplorScreen>(find.byType(EksplorScreen)).recipes, hasLength(24));
    await tester.enterText(find.byType(TextField), 'Opor');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final loadMore = find.widgetWithText(OutlinedButton, 'Muat lebih banyak resep');
    await tester.scrollUntilVisible(loadMore, 300,
        scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(loadMore), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(loadMore);
    await tester.pumpAndSettle();
    final explore = tester.widget<EksplorScreen>(find.byType(EksplorScreen));
    expect(explore.recipes.last.title, 'Opor halaman kedua');
    expect(find.text('Opor halaman kedua'), findsOneWidget);
    expect(explore.onLoadMore, isNull);
    expect(queries, 2);
  });

  test('Resep saya dan favorit dibaca terpisah dari halaman katalog', () async {
    var reads = 0;
    _host('queryGet', (args) {
      expect(args[1], 'recipes');
      final params = args[3]! as fs.InternalQueryParameters;
      if (++reads == 1) {
        expect(params.where, contains(equals(['authorId', '==', 'owner'])));
        return _query([_doc('recipes/milik', _recipe)]);
      }
      expect(params.where!.single!.sublist(1), ['in', ['favorit-lama']]);
      return _query([_doc('recipes/favorit-lama', _recipe)]);
    });
    expect((await RecipeService.fetchOwnRecipes('owner')).single.id, 'milik');
    expect((await RecipeService.fetchRecipesById(['favorit-lama'])).single.id, 'favorit-lama');
  });

  test('Laporan lama yang rusak tidak menutup daftar moderasi', () async {
    _host('queryGet', (_) => _query([
      _doc('reports/rusak', {'recipeId': 'r1', 'recipeTitle': 10}),
      _doc('reports/valid', {'recipeId': 'r1', 'recipeTitle': 'Sup Ayam'}),
    ]));
    final reports = await RecipeService.fetchReports();
    expect(reports.items.map((report) => report['recipeTitle']),
        containsAll(['Judul tidak tersedia', 'Sup Ayam']));
  });

  testWidgets('Admin memuat halaman pengguna berikutnya tanpa mengulang total', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var reads = 0;
    var counts = 0;
    _host('queryGet', (args) {
      expect(args[1], 'users');
      final params = args[3]! as fs.InternalQueryParameters;
      expect(params.limit, 25);
      expect(params.orderBy, [[FieldPath.documentId, false]]);
      if (++reads == 1) {
        expect(params.startAfter, isNull);
        return _query([
          for (var i = 0; i < 25; i++)
            _doc('users/u${i.toString().padLeft(2, '0')}', _profile),
        ]);
      }
      expect(params.startAfter, ['u24']);
      return _query([_doc('users/u25', {..._profile, 'name': 'Pengguna berikut'})]);
    });
    _host('aggregateQuery', (args) {
      expect(args[1], 'users');
      counts++;
      return [fs.AggregateQueryResponse(type: fs.AggregateType.count, value: 500)];
    });
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdminUsersScreen())));
    await tester.pumpAndSettle();
    expect(find.text('500'), findsOneWidget);
    expect(find.text('Pencarian hanya pada pengguna yang sudah dimuat.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pengguna berikut');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Pengguna berikut'), findsNothing);
    await tester.tap(find.text('Muat lebih banyak pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Pengguna berikut'), findsOneWidget);
    expect(find.text('Muat lebih banyak pengguna'), findsNothing);
    expect((reads, counts), (2, 1));
  });

  testWidgets('Dialog laporan menambah satu halaman dan memperbarui filter resep', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var reads = 0;
    var counts = 0;
    _host('queryGet', (args) {
      expect(args[1], 'reports');
      final params = args[3]! as fs.InternalQueryParameters;
      expect(params.limit, 25);
      expect(params.orderBy, [[FieldPath.documentId, false]]);
      if (++reads == 1) {
        expect(params.startAfter, isNull);
        return _query([
          for (var i = 0; i < 25; i++)
            _doc('reports/r${i.toString().padLeft(2, '0')}', {'status': 'resolved'}),
        ]);
      }
      expect(params.startAfter, ['r24']);
      return _query([_doc('reports/r25', {'recipeId': 'r1', 'status': 'open'})]);
    });
    _host('aggregateQuery', (args) {
      expect(args[1], 'reports');
      final params = args[2]! as fs.InternalQueryParameters;
      expect(params.where, contains(equals(['status', '==', 'open'])));
      counts++;
      return [fs.AggregateQueryResponse(type: fs.AggregateType.count, value: 3)];
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdminRecipesScreen(
      recipes: [Recipe.fromFirestore('r1', _recipe)],
      onSelectRecipe: (_) {},
      onNavigateToUpload: () {},
      onDeleteRecipe: (_) async {},
    ))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dilaporkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dilaporkan'));
    await tester.pumpAndSettle();
    expect(find.text('Sup Ayam'), findsNothing);
    await tester.tap(find.text('Laporan (3)'));
    await tester.pumpAndSettle();
    expect(reads, 1);
    await tester.tap(find.text('Muat lebih banyak laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Muat lebih banyak laporan'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Sup Ayam'), findsOneWidget);
    expect((reads, counts), (2, 1));
  });

  testWidgets('Query notifikasi dibatasi; penanda hanya mencari satu yang belum dibaca', (tester) async {
    final queries = <fs.InternalQueryParameters>[];
    _host('querySnapshot', (args) { queries.add(args[3]! as fs.InternalQueryParameters); return 'audit-query'; });
    Widget home(String name) => MaterialApp(theme: AppTheme.lightTheme(),
      home: Scaffold(body: BerandaScreen(
        userId: 'owner', userName: name, recipes: const [],
        onSelectRecipe: (_) {}, onToggleFavorite: (_) {}, onNavigateToExplore: () {},
      )),
    );
    await tester.pumpWidget(home('Oma'));
    await tester.pumpAndSettle();
    expect(queries.single.limit, 1);
    expect(queries.single.where, contains(equals(['seen', '==', false])));
    expect(queries.single.where, contains(equals(['recipientId', '==', 'owner'])));
    await tester.pumpWidget(home('Oma Baru'));
    await tester.pumpAndSettle();
    expect(queries, hasLength(1));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: NotificationsSheet(uid: 'owner'),
    )));
    await tester.pump();
    expect(queries, hasLength(2));
    expect(queries.last.limit, 30);
    expect(queries.last.orderBy, [['createdAt', true]]);
  });

  test('Ulasan diurutkan dan dibatasi di server', () async {
    _host('queryGet', (args) {
      expect(args[1], 'recipes/r1/comments');
      final params = args[3]! as fs.InternalQueryParameters;
      expect(params.limit, 20);
      expect(params.orderBy, [['createdAt', true]]);
      return _query([_doc('recipes/r1/comments/c1', {'rating': 5, 'text': 'Enak'})]);
    });
    expect((await RecipeService.fetchComments('r1')).single['rating'], 5);
  });

  testWidgets('Profil memakai count server tanpa mengunduh hubungan atau mengulang pada rebuild', (tester) async {
    var counts = 0;
    _host('queryGet', (_) => fail('Hitungan pengikut tidak boleh mengunduh dokumen'));
    _host('aggregateQuery', (args) {
      expect(args[1], 'follows');
      final params = args[2]! as fs.InternalQueryParameters;
      final followers = params.where!.first![0] == 'followingId';
      counts++;
      return [fs.AggregateQueryResponse(type: fs.AggregateType.count,
          value: followers ? 10000 : 7)];
    });
    Widget profile(String name) => MaterialApp(home: Scaffold(body: ProfilScreen(
      recipes: const [], isLoggedIn: true, userId: 'owner', userName: name,
      onSelectRecipe: (_) {}, onDeleteRecipe: (_) {}, onEditRecipe: (_) {}, onNavigateToUpload: () {},
      onNavigateToFavorites: () {}, onNavigateToAdmin: () {}, onLogout: () {}, onLogin: () {},
    )));
    await tester.pumpWidget(profile('Oma'));
    await tester.pumpAndSettle();
    expect(find.text('10000 pengikut • 7 mengikuti'), findsOneWidget);
    expect(counts, 2);
    await tester.pumpWidget(profile('Oma Baru'));
    await tester.pumpAndSettle();
    expect(counts, 2);
  });
}
