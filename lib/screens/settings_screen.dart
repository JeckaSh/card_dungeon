import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../services/locale_service.dart';

/// Экран настроек приложения.
///
/// В данный момент предоставляет:
/// * Выбор языка интерфейса (русский / английский).
///
/// Смена языка происходит мгновенно — через [LocaleService.localeNotifier],
/// на который подписан корневой [MaterialApp] в [main.dart].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final l10n = AppLocalizations(locale);
        final isRu = locale.languageCode == 'ru';

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, l10n),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            // ── Секция: Язык ─────────────────────────────
                            _SectionHeader(
                              icon: Icons.language_rounded,
                              title: l10n.settingsLanguage,
                              subtitle: l10n.settingsLanguageSubtitle,
                            ),
                            const SizedBox(height: 16),
                            _LanguageOption(
                              countryCode: 'ru',
                              nativeName: l10n.settingsLangRuNative,
                              localName: l10n.settingsLangRu,
                              isSelected: isRu,
                              onTap: () => _selectLocale(const Locale('ru')),
                            ),
                            const SizedBox(height: 10),
                            _LanguageOption(
                              countryCode: 'en',
                              nativeName: l10n.settingsLangEnNative,
                              localName: l10n.settingsLangEn,
                              isSelected: !isRu,
                              onTap: () => _selectLocale(const Locale('en')),
                            ),
                            const SizedBox(height: 16),
                            // Подсказка
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      l10n.settingsRestartHint,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.45),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
            ),
            tooltip: l10n.back,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.tune_rounded,
            color: Color(0xFFE94560),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            l10n.settingsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocale(Locale locale) async {
    await LocaleService.instance.setLocale(locale);
    // setState вызывается автоматически через ValueListenableBuilder
  }
}

// ── Виджеты ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE94560).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE94560).withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFE94560)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.countryCode,
    required this.nativeName,
    required this.localName,
    required this.isSelected,
    required this.onTap,
  });

  final String countryCode;
  final String nativeName;
  final String localName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE94560);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.12),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Графический флаг (одинаково отображается на Windows, Mac, Android и iOS)
              _CountryFlagWidget(countryCode: countryCode),
              const SizedBox(width: 16),
              // Названия
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (localName != nativeName)
                      Text(
                        localName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              // Индикатор выбора
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? accent
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для кроссплатформенного отображения флагов стран (включая Windows,
/// где эмодзи флагов рендерятся как буквы RU / GB).
class _CountryFlagWidget extends StatelessWidget {
  const _CountryFlagWidget({required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: countryCode == 'ru'
            ? const _RussianFlag()
            : const _BritishFlag(),
      ),
    );
  }
}

/// Российский триколор (Белый, Синий, Красный)
class _RussianFlag extends StatelessWidget {
  const _RussianFlag();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(36, 24),
      painter: _RussianFlagPainter(),
    );
  }
}

class _RussianFlagPainter extends CustomPainter {
  const _RussianFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripeH = size.height / 3;
    final w = size.width;

    // 1. Белая полоса (верх)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, stripeH),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    // 2. Синяя полоса (центр)
    canvas.drawRect(
      Rect.fromLTWH(0, stripeH, w, stripeH),
      Paint()..color = const Color(0xFF0039A6),
    );
    // 3. Красная полоса (низ)
    canvas.drawRect(
      Rect.fromLTWH(0, stripeH * 2, w, size.height - stripeH * 2),
      Paint()..color = const Color(0xFFD52B1E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Британский флаг (Union Jack)
class _BritishFlag extends StatelessWidget {
  const _BritishFlag();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(36, 24),
      painter: _UkFlagPainter(),
    );
  }
}

class _UkFlagPainter extends CustomPainter {
  const _UkFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Синий фон
    final bluePaint = Paint()..color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bluePaint);

    // 2. Белый Андреевский диагональный крест
    final whiteDiagonalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), whiteDiagonalPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), whiteDiagonalPaint);

    // 3. Красный диагональный крест Святого Патрика
    final redDiagonalPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, h), redDiagonalPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), redDiagonalPaint);

    // 4. Белый прямой крест Святого Георгия (подложка)
    final whiteCrossPaint = Paint()..color = Colors.white;
    final whiteCrossW = w * 0.32;
    final whiteCrossH = h * 0.38;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: whiteCrossW,
        height: h,
      ),
      whiteCrossPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: w,
        height: whiteCrossH,
      ),
      whiteCrossPaint,
    );

    // 5. Красный прямой крест Святого Георгия
    final redCrossPaint = Paint()..color = const Color(0xFFC8102E);
    final redCrossW = w * 0.18;
    final redCrossH = h * 0.22;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: redCrossW,
        height: h,
      ),
      redCrossPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: w,
        height: redCrossH,
      ),
      redCrossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
