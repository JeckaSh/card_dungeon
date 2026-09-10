import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/models/event_card.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';

void main() {
  const testEvent = EventCard(
    id: 'test_monster',
    type: EventType.monster,
    title: 'Гоблин',
    description: 'Маленький, но злобный гоблин преграждает путь.',
    leftChoice: CardChoice(
      label: 'Атаковать',
      healthDelta: -2,
      coinsDelta: 5,
    ),
    rightChoice: CardChoice(
      label: 'Убежать',
    ),
  );

  testWidgets('SwipeCard adapts properly on small and standard screens', (tester) async {
    // 1. Phone screen (380 x 700)
    tester.view.physicalSize = const Size(380, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool swiped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              height: 500,
              child: SwipeCard(
                event: testEvent,
                currentCoins: 10,
                currentAttack: 5,
                onSwipe: (isRight) {
                  swiped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardFinder = find.text('Гоблин');
    expect(cardFinder, findsOneWidget);

    final cardContainer = find.descendant(
      of: find.byType(SwipeCard),
      matching: find.byType(ClipRRect),
    ).first;
    final phoneCardSize = tester.getSize(cardContainer);
    // On small screen (380 dp width), card width is scaled up by 10% (~158 dp)
    expect(phoneCardSize.width, inInclusiveRange(150.0, 185.0));

    // 2. Swiping right works on small screen
    await tester.drag(cardFinder, const Offset(150, 0));
    await tester.pumpAndSettle();
    expect(swiped, isTrue);
  });
}
