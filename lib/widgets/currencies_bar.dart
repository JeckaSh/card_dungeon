import 'package:flutter/material.dart';

import '../app_localizations.dart';
import '../services/player_coins_service.dart';

/// Виджет панели валют игрока.
///
/// Отображает три постоянные валюты:
/// 1. 🪙 Монеты (Coins);
/// 2. 🗝️ Серебряные ключи (Silver Keys);
/// 3. 🔑 Золотые ключи (Gold Keys).
///
/// Автоматически перерисовывается при изменении [PlayerCoinsService].
class PlayerCurrenciesBar extends StatelessWidget {
  const PlayerCurrenciesBar({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: PlayerCoinsService.instance,
      builder: (context, _) {
        final coins = PlayerCoinsService.instance.coins;
        final silverKeys = PlayerCoinsService.instance.silverKeys;
        final goldKeys = PlayerCoinsService.instance.goldKeys;

        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E2238),
                Color(0xFF14172B),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  l10n.shopYourBalance,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
              // ── 1. Монеты ───────────────────────────────────────────
              Expanded(
                child: _CurrencySlot(
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFFFFD700),
                  bgGradient: [
                    const Color(0xFFFFD700).withValues(alpha: 0.18),
                    const Color(0xFFFF8C00).withValues(alpha: 0.08),
                  ],
                  borderColor: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  label: l10n.inventoryBalance, // 'Монеты'
                  value: '$coins',
                  tooltip: l10n.currencyCoinsTooltip,
                ),
              ),
              const SizedBox(width: 8),

              // ── 2. Серебряные ключи ─────────────────────────────────
              Expanded(
                child: _CurrencySlot(
                  icon: Icons.vpn_key_rounded,
                  iconColor: const Color(0xFFDDE4F0),
                  bgGradient: [
                    const Color(0xFFCFD8DC).withValues(alpha: 0.18),
                    const Color(0xFF90A4AE).withValues(alpha: 0.08),
                  ],
                  borderColor: const Color(0xFFB0BEC5).withValues(alpha: 0.35),
                  label: l10n.currencySilverKeysShort, // 'Сер. ключи'
                  value: '$silverKeys',
                  tooltip: l10n.currencySilverKeysTooltip,
                ),
              ),
              const SizedBox(width: 8),

              // ── 3. Золотые ключи ───────────────────────────────────
              Expanded(
                child: _CurrencySlot(
                  icon: Icons.key_rounded,
                  iconColor: const Color(0xFFFFB300),
                  bgGradient: [
                    const Color(0xFFFFB300).withValues(alpha: 0.18),
                    const Color(0xFFFF8F00).withValues(alpha: 0.08),
                  ],
                  borderColor: const Color(0xFFFFA000).withValues(alpha: 0.35),
                  label: l10n.currencyGoldKeysShort, // 'Зол. ключи'
                  value: '$goldKeys',
                  tooltip: l10n.currencyGoldKeysTooltip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }
}

class _CurrencySlot extends StatelessWidget {
  const _CurrencySlot({
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
    required this.borderColor,
    required this.label,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final Color iconColor;
  final List<Color> bgGradient;
  final Color borderColor;
  final String label;
  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
