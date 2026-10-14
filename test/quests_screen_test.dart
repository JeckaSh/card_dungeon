import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/main.dart';
import 'package:kki_cardgame/screens/quests_screen.dart';
import 'package:kki_cardgame/services/daily_quests_service.dart';
import 'package:kki_cardgame/services/daily_reward_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/widgets/daily_reward_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerCoinsService.instance.load();
    PlayerCoinsService.instance.restoreBalance(0);
    await DailyRewardService.instance.debugResetStreak();
  });

  testWidgets('MenuScreen contains Задания button between Инвентарь and Глоссарий', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Prevent auto-popup to test menu buttons cleanly
    await DailyRewardService.instance.debugSetStreak(1, claimedToday: true);

    await tester.pumpWidget(const DungeonCardsApp());
    await tester.pumpAndSettle();

    expect(find.text('Инвентарь'), findsOneWidget);
    expect(find.text('Задания'), findsOneWidget);
    expect(find.text('Глоссарий'), findsOneWidget);

    final inventoryCenter = tester.getCenter(find.text('Инвентарь'));
    final questsCenter = tester.getCenter(find.text('Задания'));
    final glossaryCenter = tester.getCenter(find.text('Глоссарий'));

    // Verify vertical order: Inventory -> Quests -> Glossary
    expect(questsCenter.dy, greaterThan(inventoryCenter.dy));
    expect(glossaryCenter.dy, greaterThan(questsCenter.dy));

    // Tap "Задания" and verify QuestsScreen opens
    await tester.tap(find.text('Задания'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestsScreen), findsOneWidget);
    expect(find.text('Ежедневный вход'), findsOneWidget);
    expect(find.text('Серия входов (7 дней)'), findsOneWidget);
  });

  testWidgets('DailyRewardDialog shows current streak day and claims reward', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDailyRewardDialog(context),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(DailyRewardDialog), findsOneWidget);
    expect(find.text('Награда за вход'), findsOneWidget);
    expect(find.text('День 1 из 7'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('Забрать награду'), findsOneWidget);

    // Tap claim
    await tester.tap(find.text('Забрать награду'));
    await tester.pumpAndSettle();

    // Dialog closes
    expect(find.byType(DailyRewardDialog), findsNothing);
    // 100 coins credited
    expect(PlayerCoinsService.instance.balance, 100);
    expect(DailyRewardService.instance.isClaimedToday, isTrue);
  });

  testWidgets('QuestsScreen displays 7 days streak and allows claiming today', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: QuestsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Задания'), findsOneWidget);
    expect(find.text('Ежедневный вход'), findsOneWidget);
    expect(find.text('День 1 из 7'), findsOneWidget);
    expect(find.text('День 7 👑'), findsOneWidget);
    expect(find.textContaining('Забрать награду (+100 🪙)'), findsOneWidget);

    // Claim reward in QuestsScreen
    await tester.tap(find.textContaining('Забрать награду (+100 🪙)'));
    await tester.pumpAndSettle();

    expect(PlayerCoinsService.instance.balance, 100);
    expect(find.text('Получено сегодня'), findsWidgets);
  });

  testWidgets('QuestsScreen displays 2 daily quests and allows claiming completed quest for 150 coins', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    DailyQuestsService.instance.setQuestsForTesting([
      DailyQuest(
        id: 'quest_1',
        type: DailyQuestType.clearDungeon,
        target: 1,
        progress: 1,
      ),
      DailyQuest(
        id: 'quest_2',
        type: DailyQuestType.killBosses,
        target: 4,
        progress: 1,
      ),
    ]);

    await tester.pumpWidget(
      const MaterialApp(
        home: QuestsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ежедневные задания'), findsOneWidget);
    expect(find.text('Пройти 1 подземелье'), findsOneWidget);
    expect(find.text('Убить 4 босса'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);

    // First quest is completed and can be claimed
    expect(find.text('Забрать (+150 🪙)'), findsOneWidget);

    // Tap claim for quest 1
    await tester.tap(find.text('Забрать (+150 🪙)'));
    await tester.pumpAndSettle();

    expect(PlayerCoinsService.instance.balance, 150);
    expect(find.text('Получено'), findsWidgets);
  });
}
