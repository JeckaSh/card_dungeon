import 'package:shared_preferences/shared_preferences.dart';
import 'player_coins_service.dart';
import 'unlocked_items_service.dart';

/// Сервис управления прокачкой постоянных стартовых характеристик персонажа.
///
/// Все улучшения приобретаются за накопленные монеты ([PlayerCoinsService])
/// на экране инвентаря ([InventoryScreen]) и сохраняются между сессиями
/// через [SharedPreferences].
///
/// Доступные направления прокачки:
/// 1. **Здоровье** ([healthLevel]): базовое 10 HP, +2 HP за уровень, макс. 10 уровней.
/// 2. **Атака** ([attackLevel]): базовая 5 ⚡, +1 ⚡ за уровень, макс. 10 уровней.
/// 3. **Торговцы** ([merchantLevel]): гарантирует появление 1-2 торговцев на каждом этаже до босса.
/// 4. **Стартовые карты** ([startingCardsLevel]): выдаёт 1-3 случайных открытых артефакта
///    в инвентарь в начале забега (требует минимум 3 открытые карты в коллекции).
class PlayerStatsService {
  PlayerStatsService._();

  /// Глобальный синглтон сервиса
  static final PlayerStatsService instance = PlayerStatsService._();

  static const _healthLevelKey = 'player_health_upgrade_level';
  static const _attackLevelKey = 'player_attack_upgrade_level';
  static const _merchantLevelKey = 'player_merchant_upgrade_level';
  static const _startingCardsLevelKey = 'player_starting_cards_upgrade_level';

  /// Базовое значение здоровья без улучшений
  static const int baseHealth = 10;

  /// Прирост здоровья за каждый уровень улучшения
  static const int healthPerLevel = 2;

  /// Максимальный уровень улучшения здоровья
  static const int maxHealthLevel = 10;

  /// Базовое значение силы атаки без улучшений
  static const int baseAttack = 5;

  /// Прирост силы атаки за каждый уровень улучшения
  static const int attackPerLevel = 1;

  /// Максимальный уровень улучшения атаки
  static const int maxAttackLevel = 10;

  /// Максимальное количество гарантированных торговцев за уровень (0..2)
  static const int maxMerchantLevel = 2;

  /// Базовая стоимость первого уровня торговцев
  static const int merchantUpgradeCostBase = 60;

  /// Максимальный уровень навыка стартовых карт (0..3)
  static const int maxStartingCardsLevel = 3;

  /// Базовая стоимость первого уровня стартовых карт
  static const int startingCardsUpgradeCostBase = 50;

  /// Минимальное количество открытых карт в коллекции для разблокировки прокачки навыка
  static const int requiredUnlockedCardsForStartingCards = 3;

  int _healthLevel = 0;
  int _attackLevel = 0;
  int _merchantLevel = 0;
  int _startingCardsLevel = 0;
  bool _loaded = false;

  /// Текущий уровень улучшения здоровья (0..10)
  int get healthLevel => _healthLevel;

  /// Текущий уровень улучшения атаки (0..10)
  int get attackLevel => _attackLevel;

  /// Текущий уровень улучшения торговцев (0..2)
  int get merchantLevel => _merchantLevel;

  /// Текущий уровень улучшения стартовых карт (0..3)
  int get startingCardsLevel => _startingCardsLevel;

  /// Стартовое здоровье персонажа в начале игры с учётом прокачки
  int get startingHealth => baseHealth + _healthLevel * healthPerLevel;

  /// Стартовая атака персонажа в начале игры с учётом прокачки
  int get startingAttack => baseAttack + _attackLevel * attackPerLevel;

  /// Количество случайных карт, выдаваемых при старте игры (уровень 1 = 1, уровень 2 = 2, уровень 3 = 3)
  int get startingCardsCount => _startingCardsLevel;

  /// Достигнут ли максимум прокачки здоровья
  bool get isHealthMax => _healthLevel >= maxHealthLevel;

  /// Достигнут ли максимум прокачки атаки
  bool get isAttackMax => _attackLevel >= maxAttackLevel;

  /// Достигнут ли максимум прокачки торговцев
  bool get isMerchantMax => _merchantLevel >= maxMerchantLevel;

  /// Достигнут ли максимум прокачки стартовых карт
  bool get isStartingCardsMax => _startingCardsLevel >= maxStartingCardsLevel;

  /// Доступен ли навык стартовых карт для прокачки (требуется минимум 3 открытые карты)
  bool get isStartingCardsUnlocked =>
      UnlockedItemsService.instance.count >=
      requiredUnlockedCardsForStartingCards;

  /// Количество гарантированных торговцев за уровень (0 = не гарантировано)
  int get guaranteedMerchants => _merchantLevel;

  /// Стоимость следующего уровня здоровья (25, 50, 75, 100...)
  int get healthUpgradeCost => 25 + _healthLevel * 25;

  /// Стоимость следующего уровня атаки (30, 60, 90, 120...)
  int get attackUpgradeCost => 30 + _attackLevel * 30;

  /// Стоимость следующего уровня торговцев (60, 100)
  int get merchantUpgradeCost => merchantUpgradeCostBase + _merchantLevel * 40;

  /// Стоимость следующего уровня стартовых карт (50, 100, 150)
  int get startingCardsUpgradeCost =>
      startingCardsUpgradeCostBase + _startingCardsLevel * 50;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _healthLevel = (prefs.getInt(_healthLevelKey) ?? 0).clamp(
      0,
      maxHealthLevel,
    );
    _attackLevel = (prefs.getInt(_attackLevelKey) ?? 0).clamp(
      0,
      maxAttackLevel,
    );
    _merchantLevel = (prefs.getInt(_merchantLevelKey) ?? 0).clamp(
      0,
      maxMerchantLevel,
    );
    _startingCardsLevel = (prefs.getInt(_startingCardsLevelKey) ?? 0).clamp(
      0,
      maxStartingCardsLevel,
    );
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

  /// Прокачка торговцев за монеты
  bool upgradeMerchant() {
    if (isMerchantMax) return false;
    final cost = merchantUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _merchantLevel++;
    _persistAsync();
    return true;
  }

  /// Прокачка стартовых карт за монеты (доступна при открытии хотя бы 3 карт)
  bool upgradeStartingCards() {
    if (!isStartingCardsUnlocked || isStartingCardsMax) return false;
    final cost = startingCardsUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _startingCardsLevel++;
    _persistAsync();
    return true;
  }

  void _persistAsync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_healthLevelKey, _healthLevel);
      prefs.setInt(_attackLevelKey, _attackLevel);
      prefs.setInt(_merchantLevelKey, _merchantLevel);
      prefs.setInt(_startingCardsLevelKey, _startingCardsLevel);
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

  /// Прямая установка уровня торговцев (для настроек/отладки)
  void setMerchantLevel(int level) {
    _merchantLevel = level.clamp(0, maxMerchantLevel);
    _persistAsync();
  }

  /// Прямая установка уровня стартовых карт (для настроек/отладки)
  void setStartingCardsLevel(int level) {
    _startingCardsLevel = level.clamp(0, maxStartingCardsLevel);
    _persistAsync();
  }

  /// Сброс уровней прокачки
  void resetStats() {
    _healthLevel = 0;
    _attackLevel = 0;
    _merchantLevel = 0;
    _startingCardsLevel = 0;
    _persistAsync();
  }

  /// Для тестов: сброс состояния
  void resetForTest() {
    _healthLevel = 0;
    _attackLevel = 0;
    _merchantLevel = 0;
    _startingCardsLevel = 0;
    _loaded = true;
  }

  /// Для тестов: установка уровней улучшений напрямую
  void setLevelsForTest({
    int? health,
    int? attack,
    int? merchant,
    int? startingCards,
  }) {
    if (health != null) _healthLevel = health.clamp(0, maxHealthLevel);
    if (attack != null) _attackLevel = attack.clamp(0, maxAttackLevel);
    if (merchant != null) _merchantLevel = merchant.clamp(0, maxMerchantLevel);
    if (startingCards != null) {
      _startingCardsLevel = startingCards.clamp(0, maxStartingCardsLevel);
    }
    _loaded = true;
  }
}
