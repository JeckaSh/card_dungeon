import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/menu_screen.dart';
import 'services/daily_quests_service.dart';
import 'services/daily_reward_service.dart';
import 'services/locale_service.dart';
import 'services/player_coins_service.dart';

/// Точка входа в мобильное приложение Card Dungeon.
///
/// Фиксирует портретную ориентацию экрана, загружает настройки языка
/// и запускает [DungeonCardsApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Future.wait([
    LocaleService.instance.load(),
    PlayerCoinsService.instance.load(),
    DailyRewardService.instance.load(),
    DailyQuestsService.instance.load(),
  ]);
  runApp(const DungeonCardsApp());
}

/// Корневой виджет приложения с глобальной тёмной темой.
///
/// Реактивно перестраивается при смене языка через [LocaleService.localeNotifier].
class DungeonCardsApp extends StatelessWidget {
  const DungeonCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: locale.languageCode == 'ru' ? 'Подземелье' : 'Dungeon',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _NoScrollbarBehavior(),
          locale: locale,
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0F1A),
            fontFamily: 'Roboto',
            useMaterial3: true,
            scrollbarTheme: const ScrollbarThemeData(
              thumbVisibility: WidgetStatePropertyAll(false),
              trackVisibility: WidgetStatePropertyAll(false),
              thickness: WidgetStatePropertyAll(0),
            ),
          ),
          home: const MenuScreen(),
        );
      },
    );
  }
}

/// Кастомное поведение скролла, отключающее системный индикатор прокрутки (скроллбар) на всех экранах.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
