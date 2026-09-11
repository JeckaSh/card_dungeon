import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/debug_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/services/run_chronicle_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
  });

  testWidgets('DebugScreen shows hero upgrade controls and allows changing levels', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: DebugScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify upgrade section exists
    expect(find.text('Прокачка характеристик героя'), findsOneWidget);
    expect(find.text('Уровень здоровья'), findsOneWidget);
    expect(find.text('Уровень атаки'), findsOneWidget);
    expect(find.text('Уровень торговцев'), findsOneWidget);
    expect(find.text('Уровень стартовых карт'), findsOneWidget);

    // Initial state: Level 0
    expect(PlayerStatsService.instance.healthLevel, 0);
    expect(PlayerStatsService.instance.attackLevel, 0);
    expect(PlayerStatsService.instance.merchantLevel, 0);
    expect(PlayerStatsService.instance.startingCardsLevel, 0);
    expect(find.text('Ур. 0 / 10'), findsNWidgets(2));
    expect(find.text('Ур. 0 / 2'), findsOneWidget);
    expect(find.text('Ур. 0 / 3'), findsOneWidget);

    // Tap Max button in health card
    final maxButtons = find.text('Макс (10)');
    expect(maxButtons, findsNWidgets(2));
    await tester.tap(maxButtons.first);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 10);
    expect(find.text('Ур. 10 / 10'), findsOneWidget);

    // Tap + button on attack card (2nd + button out of 4)
    final addButtons = find.byIcon(Icons.add_circle_outline);
    expect(addButtons, findsNWidgets(4));
    await tester.tap(addButtons.at(1));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.attackLevel, 1);
    expect(find.text('Ур. 1 / 10'), findsOneWidget);

    // Tap + button on merchant card (3rd + button out of 4)
    await tester.tap(addButtons.at(2));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.merchantLevel, 1);
    expect(find.text('Ур. 1 / 2'), findsOneWidget);

    // Tap + button on starting cards card (4th + button out of 4)
    await tester.tap(addButtons.at(3));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.startingCardsLevel, 1);
    expect(find.text('Ур. 1 / 3'), findsOneWidget);

    // Tap 'Сбросить в 0'
    await tester.tap(find.text('Сбросить в 0'));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 0);
    expect(PlayerStatsService.instance.attackLevel, 0);
    expect(PlayerStatsService.instance.merchantLevel, 0);
    expect(PlayerStatsService.instance.startingCardsLevel, 0);
    expect(find.text('Ур. 0 / 10'), findsNWidgets(2));
    expect(find.text('Ур. 0 / 2'), findsOneWidget);
    expect(find.text('Ур. 0 / 3'), findsOneWidget);

    // Tap 'Максимум (10/10/2/3)'
    await tester.tap(find.text('Максимум (10/10/2/3)'));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 10);
    expect(PlayerStatsService.instance.attackLevel, 10);
    expect(PlayerStatsService.instance.merchantLevel, 2);
    expect(PlayerStatsService.instance.startingCardsLevel, 3);
    expect(find.text('Ур. 10 / 10'), findsNWidgets(2));
    expect(find.text('Ур. 2 / 2'), findsOneWidget);
    expect(find.text('Ур. 3 / 3'), findsOneWidget);
  });

  testWidgets('DebugScreen shows chronicle section and allows clearing chronicle', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Add dummy runs to chronicle
    await RunChronicleService.instance.load();
    await RunChronicleService.instance.addRecord(
      RunRecord(
        endedAt: DateTime.now(),
        cardsPassed: 15,
        dungeonLevel: 2,
        coins: 80,
        isVictory: false,
        journal: ['Тестовая запись'],
      ),
    );
    expect(RunChronicleService.instance.records.length, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: DebugScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Хроника забегов'), findsOneWidget);
    expect(find.text('Записей: 1 / 10'), findsOneWidget);

    final clearButton = find.text('Очистить хронику');
    expect(clearButton, findsOneWidget);

    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(RunChronicleService.instance.records.isEmpty, isTrue);
    expect(find.text('Записей: 0 / 10'), findsOneWidget);
  });
}
