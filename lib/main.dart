import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu_screen.dart';

/// Точка входа в мобильное приложение Card Dungeon.
///
/// Фиксирует портретную ориентацию экрана и запускает [DungeonCardsApp].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const DungeonCardsApp());
}

/// Корневой виджет приложения с глобальной тёмной темой.
class DungeonCardsApp extends StatelessWidget {
  const DungeonCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Подземелье',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}
