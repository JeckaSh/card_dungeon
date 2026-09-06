import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/debug_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
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

    // Initial state: Level 0
    expect(PlayerStatsService.instance.healthLevel, 0);
    expect(PlayerStatsService.instance.attackLevel, 0);
    expect(find.text('Ур. 0 / 10'), findsNWidgets(2));

    // Tap Max button in health card
    final maxButtons = find.text('Макс (10)');
    expect(maxButtons, findsNWidgets(2));
    await tester.tap(maxButtons.first);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 10);
    expect(find.text('Ур. 10 / 10'), findsOneWidget);

    // Tap + button on attack card (2nd + button)
    final addButtons = find.byIcon(Icons.add_circle_outline);
    expect(addButtons, findsNWidgets(2));
    await tester.tap(addButtons.last);
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.attackLevel, 1);
    expect(find.text('Ур. 1 / 10'), findsOneWidget);

    // Tap 'Сбросить в 0'
    await tester.tap(find.text('Сбросить в 0'));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 0);
    expect(PlayerStatsService.instance.attackLevel, 0);
    expect(find.text('Ур. 0 / 10'), findsNWidgets(2));

    // Tap 'Максимум (10/10)'
    await tester.tap(find.text('Максимум (10/10)'));
    await tester.pumpAndSettle();

    expect(PlayerStatsService.instance.healthLevel, 10);
    expect(PlayerStatsService.instance.attackLevel, 10);
    expect(find.text('Ур. 10 / 10'), findsNWidgets(2));
  });
}
