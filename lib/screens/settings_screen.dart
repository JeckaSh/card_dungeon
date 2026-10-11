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
                              flag: '🇷🇺',
                              nativeName: l10n.settingsLangRuNative,
                              localName: l10n.settingsLangRu,
                              isSelected: isRu,
                              onTap: () => _selectLocale(const Locale('ru')),
                            ),
                            const SizedBox(height: 10),
                            _LanguageOption(
                              flag: '🇬🇧',
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
    required this.flag,
    required this.nativeName,
    required this.localName,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
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
              // Флаг
              Text(flag, style: const TextStyle(fontSize: 28)),
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
