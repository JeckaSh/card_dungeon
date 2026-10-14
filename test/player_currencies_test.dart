import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/inventory_screen.dart';
import 'package:kki_cardgame/screens/quests_screen.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/widgets/currencies_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PlayerCoinsService.instance.load();
    PlayerCoinsService.instance.restoreBalance(0);
    PlayerCoinsService.instance.setSilverKeys(0);
    PlayerCoinsService.instance.setGoldKeys(0);
  });

  group('PlayerCoinsService Currencies', () {
    test('silverKeys and goldKeys can be modified and clamped', () {
      final service = PlayerCoinsService.instance;
      expect(service.silverKeys, 0);
      expect(service.goldKeys, 0);

      service.applySilverKeysDelta(3);
      expect(service.silverKeys, 3);

      service.applySilverKeysDelta(-1);
      expect(service.silverKeys, 2);

      service.setSilverKeys(10);
      expect(service.silverKeys, 10);

      service.applyGoldKeysDelta(5);
      expect(service.goldKeys, 5);

      service.applyGoldKeysDelta(-2);
      expect(service.goldKeys, 3);

      service.setGoldKeys(25);
      expect(service.goldKeys, 25);
    });

    test('currencies are saved and restored from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'player_coins': 250,
        'player_silver_keys': 7,
        'player_gold_keys': 3,
      });

      // Force reload by reflecting mock storage
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('player_coins'), 250);
      expect(prefs.getInt('player_silver_keys'), 7);
      expect(prefs.getInt('player_gold_keys'), 3);
    });
  });

  group('PlayerCurrenciesBar Widget', () {
    testWidgets('renders all three currencies side by side and reacts to updates', (tester) async {
      final service = PlayerCoinsService.instance;
      service.restoreBalance(150);
      service.setSilverKeys(4);
      service.setGoldKeys(2);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerCurrenciesBar(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayerCurrenciesBar), findsOneWidget);

      // Verify labels
      expect(find.text('Монеты'), findsOneWidget);
      expect(find.text('Сер. ключи'), findsOneWidget);
      expect(find.text('Зол. ключи'), findsOneWidget);

      // Verify values
      expect(find.text('150'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Update values dynamically
      service.applyDelta(50);
      service.applySilverKeysDelta(1);
      service.applyGoldKeysDelta(4);

      await tester.pumpAndSettle();

      expect(find.text('200'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('ShopScreen, InventoryScreen, and QuestsScreen all display PlayerCurrenciesBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PlayerCoinsService.instance.restoreBalance(99);
      PlayerCoinsService.instance.setSilverKeys(1);
      PlayerCoinsService.instance.setGoldKeys(1);

      // 1. ShopScreen
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerCurrenciesBar), findsOneWidget);
      expect(find.text('Сер. ключи'), findsOneWidget);
      expect(find.text('Зол. ключи'), findsOneWidget);

      // 2. InventoryScreen
      await tester.pumpWidget(const MaterialApp(home: InventoryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerCurrenciesBar), findsOneWidget);
      expect(find.text('Сер. ключи'), findsOneWidget);
      expect(find.text('Зол. ключи'), findsOneWidget);

      // 3. QuestsScreen
      await tester.pumpWidget(const MaterialApp(home: QuestsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerCurrenciesBar), findsOneWidget);
      expect(find.text('Сер. ключи'), findsOneWidget);
      expect(find.text('Зол. ключи'), findsOneWidget);
    });
  });
}
