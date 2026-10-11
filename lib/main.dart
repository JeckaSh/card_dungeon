import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/menu_screen.dart';
import 'services/locale_service.dart';

/// Точка входа в мобильное приложение Card Dungeon.
///
/// Фиксирует портретную ориентацию экрана, загружает настройки языка
/// и запускает [DungeonCardsApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await LocaleService.instance.load();
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
          ),
          home: const MenuScreen(),
        );
      },
    );
  }
}
