import 'package:shared_preferences/shared_preferences.dart';
import 'player_coins_service.dart';

/// Сервис прокачки постоянных стартовых характеристик персонажа.
class PlayerStatsService {
  PlayerStatsService._();

  static final PlayerStatsService instance = PlayerStatsService._();

  static const _healthLevelKey = 'player_health_upgrade_level';
  static const _attackLevelKey = 'player_attack_upgrade_level';

  static const int baseHealth = 10;
  static const int healthPerLevel = 2;
  static const int maxHealthLevel = 10;

  static const int baseAttack = 3;
  static const int attackPerLevel = 1;
  static const int maxAttackLevel = 10;

  int _healthLevel = 0;
  int _attackLevel = 0;
  bool _loaded = false;

  int get healthLevel => _healthLevel;
  int get attackLevel => _attackLevel;

  /// Стартовое здоровье персонажа в начале игры
  int get startingHealth => baseHealth + _healthLevel * healthPerLevel;

  /// Стартовая атака персонажа в начале игры
  int get startingAttack => baseAttack + _attackLevel * attackPerLevel;

  bool get isHealthMax => _healthLevel >= maxHealthLevel;
  bool get isAttackMax => _attackLevel >= maxAttackLevel;

  /// Стоимость следующего уровня здоровья
  int get healthUpgradeCost => 25 + _healthLevel * 25;

  /// Стоимость следующего уровня атаки
  int get attackUpgradeCost => 30 + _attackLevel * 30;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _healthLevel = (prefs.getInt(_healthLevelKey) ?? 0).clamp(0, maxHealthLevel);
    _attackLevel = (prefs.getInt(_attackLevelKey) ?? 0).clamp(0, maxAttackLevel);
    _loaded = true;
  }

  /// Прокачка здоровья за монеты
  bool upgradeHealth() {
    if (isHealthMax) return false;
    final cost = healthUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _healthLevel++;
    _persistAsync();
    return true;
  }

  /// Прокачка атаки за монеты
  bool upgradeAttack() {
    if (isAttackMax) return false;
    final cost = attackUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _attackLevel++;
    _persistAsync();
    return true;
  }

  void _persistAsync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_healthLevelKey, _healthLevel);
      prefs.setInt(_attackLevelKey, _attackLevel);
    });
  }

  /// Прямая установка уровня здоровья (для настроек/отладки)
  void setHealthLevel(int level) {
    _healthLevel = level.clamp(0, maxHealthLevel);
    _persistAsync();
  }

  /// Прямая установка уровня атаки (для настроек/отладки)
  void setAttackLevel(int level) {
    _attackLevel = level.clamp(0, maxAttackLevel);
    _persistAsync();
  }

  /// Сброс уровней прокачки
  void resetStats() {
    _healthLevel = 0;
    _attackLevel = 0;
    _persistAsync();
  }

  /// Для тестов: сброс состояния
  void resetForTest() {
    _healthLevel = 0;
    _attackLevel = 0;
    _loaded = true;
  }
}

