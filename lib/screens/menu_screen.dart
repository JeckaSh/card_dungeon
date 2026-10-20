import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../services/daily_quests_service.dart';
import '../services/daily_reward_service.dart';
import '../services/locale_service.dart';
import '../services/player_coins_service.dart';
import '../widgets/daily_reward_dialog.dart';
import 'chronicle_screen.dart';
import 'debug_screen.dart';
import 'dungeon_select_screen.dart';
import 'glossary_screen.dart';
import 'inventory_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'tutorial_screen.dart';

/// Главный экран игры (Меню).
///
/// Предоставляет навигацию по всем ключевым разделам:
/// * Выбор подземелья ([DungeonSelectScreen]);
/// * Магазин карт за монеты ([ShopScreen]);
/// * Инвентарь и прокачка героя ([InventoryScreen]);
/// * Задания и ежедневные награды ([QuestsScreen]);
/// * Глоссарий открытых карт ([GlossaryScreen]);
/// * Хроника прошлых забегов ([ChronicleScreen]);
/// * Интерактивное обучение основам игры ([TutorialScreen]);
/// * Настройки языка и интерфейса ([SettingsScreen]);
/// * Панель отладки и тестирования ([DebugScreen]).
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _checkedDailyReward = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  Future<void> _checkDailyReward() async {
    if (_checkedDailyReward) return;
    _checkedDailyReward = true;

    await Future.wait([
      PlayerCoinsService.instance.load(),
      DailyRewardService.instance.load(),
      DailyQuestsService.instance.load(),
    ]);

    if (!mounted) return;

    if (DailyRewardService.instance.canClaimToday) {
      showDailyRewardDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);
        return ListenableBuilder(
          listenable: Listenable.merge([
            DailyRewardService.instance,
            DailyQuestsService.instance,
          ]),
          builder: (context, _) {
            final hasNotification =
                DailyRewardService.instance.canClaimToday ||
                DailyQuestsService.instance.hasUnclaimedCompletedQuests;

            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F0F1A),
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.castle,
                                  size: 80,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  l10n.appTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.appSubtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  l10n.menuHeroDescription,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _MenuButton(
                                  label: l10n.menuDungeon,
                                  icon: Icons.explore,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const DungeonSelectScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuShop,
                                  icon: Icons.shopping_bag_outlined,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ShopScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuInventory,
                                  icon: Icons.backpack_outlined,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const InventoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Новая кнопка "Задания" между Инвентарем и Глоссарием
                                _MenuButton(
                                  label: l10n.menuQuests,
                                  icon: Icons.assignment_outlined,
                                  isSecondary: true,
                                  hasNotification: hasNotification,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const QuestsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuGlossary,
                                  icon: Icons.menu_book,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const GlossaryScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuChronicle,
                                  icon: Icons.auto_stories_rounded,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ChronicleScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuTutorial,
                                  icon: Icons.school_rounded,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const TutorialScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _MenuButton(
                                  label: l10n.menuSettings,
                                  icon: Icons.tune_rounded,
                                  isSecondary: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Номер версии в левом верхнем углу
                      Positioned(
                        top: 14,
                        left: 16,
                        // TODO: версия игры
                        child: Text(
                          'card dungeon v0.0.15',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Кнопка панели разработчика (дебаг)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Tooltip(
                          message: l10n.menuDebugTooltip,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DebugScreen(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.bug_report_outlined,
                                  color: Colors.white.withValues(alpha: 0.45),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.hasNotification = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isSecondary
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                  color: hasNotification
                      ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        color: hasNotification ? const Color(0xFFFFD700) : null,
                      ),
                      if (hasNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFFD700),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasNotification ? Colors.white : null,
                    ),
                  ),
                  if (hasNotification) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '!',
                        style: TextStyle(
                          color: Color(0xFF141424),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFE94560).withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
