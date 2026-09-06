import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/items.dart';
import 'package:kki_cardgame/screens/shop_screen.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/services/unlocked_items_service.dart';
import 'package:kki_cardgame/widgets/item_details_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tapping on an unlocked card in ShopScreen opens item details sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Unlock the first item
    await UnlockedItemsService.instance.load();
    await UnlockedItemsService.instance.unlock(allItemCards.first.id);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final firstItem = allItemCards.first;
    expect(find.text(firstItem.title), findsWidgets);

    // Tap on the first item card
    await tester.tap(find.text(firstItem.title).first);
    await tester.pumpAndSettle();

    // The details sheet should now be open
    expect(find.byType(ItemDetailsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ItemDetailsSheet),
        matching: find.text(firstItem.description),
      ),
      findsOneWidget,
    );
    expect(find.text('Открыта'), findsOneWidget);
  });

  testWidgets('Tapping on a locked card in ShopScreen does NOT open details sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find locked item widget
    final lockedFinder = find.text('В сундуке');
    expect(lockedFinder, findsWidgets);

    // Tap on the first locked card container
    await tester.tap(lockedFinder.first);
    await tester.pumpAndSettle();

    // The details sheet should NOT be opened
    expect(find.byType(ItemDetailsSheet), findsNothing);
  });

  testWidgets('Opening a chest in ShopScreen shows reward dialog without crashing', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    PlayerCoinsService.instance.restoreBalance(100);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShopScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the open chest button
    await tester.tap(find.textContaining('Открыть сундук'));
    await tester.pumpAndSettle();

    // Reward dialog should appear
    expect(find.text('Отлично'), findsOneWidget);
  });
}
