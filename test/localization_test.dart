import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/chronicle_screen.dart';
import 'package:kki_cardgame/screens/dungeon_select_screen.dart';
import 'package:kki_cardgame/screens/glossary_screen.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/screens/tutorial_screen.dart';
import 'package:kki_cardgame/services/locale_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget makeTestApp(Widget child) {
  return ValueListenableBuilder<Locale>(
    valueListenable: LocaleService.instance.localeNotifier,
    builder: (context, locale, _) {
      return MaterialApp(
        locale: locale,
        supportedLocales: const [
          Locale('ru'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      );
    },
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleService.instance.load();
    await LocaleService.instance.setLocale(const Locale('en'));
    await PlayerCoinsService.instance.load();
    await PlayerStatsService.instance.load();
    await UnlockedItemsService.instance.load();
  });

  tearDown(() async {
    await LocaleService.instance.setLocale(const Locale('ru'));
  });

  testWidgets('DungeonSelectScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const DungeonSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dungeons'), findsOneWidget);
    expect(find.text('Cursed Forest'), findsOneWidget);
    expect(find.text('Levels count: 3'), findsOneWidget);
    expect(find.text('Enter Dungeon'), findsOneWidget);
  });

  testWidgets('ShopScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const ShopScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Your balance'), findsOneWidget);
    expect(find.text('Magic Chest'), findsOneWidget);
    expect(find.text('Available Cards'), findsOneWidget);
  });

  testWidgets('InventoryScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const InventoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Character Upgrades'), findsOneWidget);
    expect(find.text('Starting Stats'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Attack'), findsOneWidget);
    expect(find.text('Merchants'), findsOneWidget);
    expect(find.text('Starting Cards'), findsOneWidget);
    expect(find.text('Unlocked Item Cards'), findsOneWidget);
  });

  testWidgets('ChronicleScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const ChronicleScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chronicle'), findsOneWidget);
    expect(find.text('No saved runs yet.'), findsOneWidget);
  });

  testWidgets('GlossaryScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const GlossaryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Glossary'), findsOneWidget);
    expect(find.text('Monster'), findsOneWidget);
  });

  testWidgets('TutorialScreen displays English strings when en locale is set', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const TutorialScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
  });
}
