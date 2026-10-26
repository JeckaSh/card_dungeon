import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/screens/tutorial_screen.dart';
import 'package:kki_cardgame/services/locale_service.dart';
import 'package:kki_cardgame/services/player_coins_service.dart';
import 'package:kki_cardgame/widgets/swipe_card.dart';
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
    await LocaleService.instance.setLocale(const Locale('ru'));
    await PlayerCoinsService.instance.load();
  });

  testWidgets('TutorialScreen displays 7 steps, allows progression, and renders field guide on completion', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(makeTestApp(const TutorialScreen()));
    await tester.pumpAndSettle();

    // Шаг 1: Развилка
    expect(find.text('Обучение'), findsOneWidget);
    expect(find.text('Шаг 1 из 7'), findsOneWidget);
    expect(find.text('Развилка в подземелье'), findsOneWidget);

    // Свайпаем вправо (+2 ⚡)
    await tester.drag(find.byType(SwipeCard), const Offset(300, 0));
    await tester.pumpAndSettle();

    // Шаг 2: Пещерный тролль (проверка блокировки свайпа влево и отображения последствий)
    expect(find.text('Шаг 2 из 7'), findsOneWidget);
    expect(find.text('Пещерный тролль'), findsOneWidget);
    expect(find.textContaining('Атака +2 ⚡'), findsOneWidget);

    // Попытка свайпа влево должна заблокироваться (нужно 10 ⚡, у героя меньше)
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pumpAndSettle();
    // Карточка осталась на Шаге 2!
    expect(find.text('Шаг 2 из 7'), findsOneWidget);

    // Свайп вправо разрешён (-2 ❤, +15 🪙)
    await tester.drag(find.byType(SwipeCard), const Offset(300, 0));
    await tester.pumpAndSettle();

    // Шаг 3: Тайник чародея (выбор предмета в инвентарь)
    expect(find.text('Шаг 3 из 7'), findsOneWidget);
    expect(find.text('Тайник чародея'), findsOneWidget);
    expect(find.textContaining('Здоровье -2 ❤'), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Шаг 4: Бродячий торговец (покупка предмета)
    expect(find.text('Шаг 4 из 7'), findsOneWidget);
    expect(find.text('Бродячий торговец'), findsOneWidget);
    expect(find.textContaining('Сладкий рулет'), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Шаг 5: Шипастый коридор (требует использования предмета)
    expect(find.text('Шаг 5 из 7'), findsOneWidget);
    expect(find.text('Шипастый коридор'), findsOneWidget);
    expect(find.textContaining('Точильный камень'), findsOneWidget);

    // Открываем инвентарь и применяем Рунический щит
    final invButton = find.widgetWithText(OutlinedButton, 'Инвентарь (4)');
    expect(invButton, findsOneWidget);
    await tester.tap(invButton);
    await tester.pumpAndSettle();

    // В шторке инвентаря нажимаем «Применить» на Руническом щите (второй предмет в списке)
    final applyButtons = find.widgetWithText(ElevatedButton, 'Применить');
    expect(applyButtons, findsWidgets);
    await tester.tap(applyButtons.at(1));
    await tester.pumpAndSettle();

    // Над карточкой отобразился текст об использовании предмета
    expect(find.textContaining('Использовано: Рунический щит'), findsOneWidget);

    // Проходим ловушку (урон поглощён щитом)
    await tester.drag(find.byType(SwipeCard), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // Шаг 6: Ядовитые споровики
    expect(find.text('Шаг 6 из 7'), findsOneWidget);
    expect(find.text('Ядовитые споровики'), findsOneWidget);
    expect(find.textContaining('Урон поглощён щитом'), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(300, 0));
    // Переход на шаг 7 (босс имеет бесконечную пульсацию, поэтому pump вместо pumpAndSettle)
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    // Шаг 7: Тренировочный Колосс (Босс)
    expect(find.text('Шаг 7 из 7'), findsOneWidget);
    expect(find.text('Тренировочный Колосс'), findsOneWidget);
    expect(find.textContaining('Атака +1 ⚡'), findsOneWidget);
    await tester.drag(find.byType(SwipeCard), const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Экран завершения обучения
    expect(find.text('Обучение завершено!'), findsOneWidget);
    expect(find.text('+50 🪙 Золота'), findsOneWidget);
    expect(find.text('Памятка искателю приключений'), findsOneWidget);
    expect(find.text('Выбор подземелья'), findsOneWidget);
    expect(find.text('Прокачка в Инвентаре'), findsOneWidget);
    expect(find.text('Магазин и 5 видов сундуков'), findsOneWidget);
    expect(find.text('Задания и награды за вход'), findsOneWidget);

    // Монеты за первое прохождение начислены
    expect(PlayerCoinsService.instance.coins, equals(50));
  });
}
