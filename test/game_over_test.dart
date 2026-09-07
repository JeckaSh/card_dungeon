import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/game_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/player_stats_service.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerStatsService.instance.resetForTest();
    PlayerCoinsService.instance.restoreBalance(100);
  });

  testWidgets('ResultOverlay renders without overflow on a small screen with many entries', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final journal = List.generate(
      12,
      (i) => JournalEntry(
        emoji: '⚔️',
        text: 'Событие $i произошло в глубоких подземельях замка',
        cardNumber: i + 1,
      ),
    );

    var restarted = false;
    var menuOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultOverlay(
            cardsPassed: 15,
            health: 0,
            attack: 5,
            dungeonLevel: 2,
            runCoins: 40,
            totalCoins: 120,
            onRestart: () => restarted = true,
            onMenu: () => menuOpened = true,
            journal: journal,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and chronicle are present
    expect(find.text('Конец приключения'), findsOneWidget);
    expect(find.text('Хроника похода'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Verify first event is rendered
    expect(find.text('Событие 0 произошло в глубоких подземельях замка'), findsOneWidget);

    // Scroll down to check the buttons at the bottom of the screen
    await tester.scrollUntilVisible(find.text('Снова в бой'), 100);
    expect(find.text('Снова в бой'), findsOneWidget);
    await tester.tap(find.text('Снова в бой'));
    expect(restarted, isTrue);

    await tester.tap(find.text('В главное меню'));
    expect(menuOpened, isTrue);
  });

  testWidgets('ResultOverlay renders correctly with empty journal', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultOverlay(
            cardsPassed: 0,
            health: 0,
            attack: 3,
            dungeonLevel: 1,
            runCoins: 0,
            totalCoins: 0,
            onRestart: () {},
            onMenu: () {},
            journal: const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Конец приключения'), findsOneWidget);
    expect(find.text('Хроника похода'), findsNothing);
    expect(find.text('Снова в бой'), findsOneWidget);
  });

  testWidgets('ResultOverlay renders victory state when isVictory is true', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultOverlay(
            cardsPassed: 40,
            health: 12,
            attack: 6,
            dungeonLevel: 2,
            runCoins: 85,
            totalCoins: 185,
            onRestart: () {},
            onMenu: () {},
            journal: [
              JournalEntry(emoji: '🏆', text: 'Подземелье успешно пройдено!', cardNumber: 40),
            ],
            isVictory: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Подземелье пройдено!'), findsOneWidget);
    expect(find.textContaining('Вы успешно прошли подземелье'), findsOneWidget);
    expect(find.text('Новый поход'), findsOneWidget);
    expect(find.text('Подземелье успешно пройдено!'), findsAtLeastNWidgets(1));
    expect(find.text('🏆'), findsOneWidget);
  });

  testWidgets('Defeating 3rd boss when level 4 has no cards displays victory screen in GameScreen', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initialDungeonLevel: 3,
          initialCardsPassed: 59, // Next card (60th) will be 3rd boss
        ),
      ),
    );
    // Boss has repeating pulse animation, so pump frame instead of pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 3rd boss is on screen
    expect(find.text('Архидемон Бездны'), findsOneWidget);
    expect(find.textContaining('готовься к бою!'), findsOneWidget);

    // Swipe left on the boss to fight ('Сразиться': -8 HP, player has 10 HP, survives with 2 HP)
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Game should transition to victory ResultOverlay because level 4 cards do not exist!
    expect(find.byType(ResultOverlay), findsOneWidget);
    expect(find.text('Подземелье пройдено!'), findsOneWidget);
    expect(find.textContaining('Вы успешно прошли подземелье'), findsOneWidget);
    expect(find.text('Новый поход'), findsOneWidget);
    expect(find.text('Подземелье успешно пройдено!'), findsAtLeastNWidgets(1));
  });
}
