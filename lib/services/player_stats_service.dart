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
  static const _merchantCardUpgradeLevelKey =
      'player_merchant_card_upgrade_level';
  static const _monsterGoldLevelKey = 'player_monster_gold_upgrade_level';
  static const _dodgeLevelKey = 'player_dodge_upgrade_level';
  static const _resistanceLevelKey = 'player_resistance_upgrade_level';

  /// Базовое значение здоровья без улучшений
  static const int baseHealth = 10;

  /// Прирост здоровья за каждый уровень улучшения
  static const int healthPerLevel = 2;

  /// Максимальный уровень улучшения здоровья
  static const int maxHealthLevel = 10;

  /// Базовая стоимость первого уровня здоровья
  static const int healthUpgradeCostBase = 100;

  /// Прирост стоимости улучшения здоровья за уровень
  static const int healthUpgradeCostPerLevel = 100;

  /// Базовое значение силы атаки без улучшений
  static const int baseAttack = 5;

  /// Прирост силы атаки за каждый уровень улучшения
  static const int attackPerLevel = 1;

  /// Максимальный уровень улучшения атаки
  static const int maxAttackLevel = 10;

  /// Базовая стоимость первого уровня атаки
  static const int attackUpgradeCostBase = 120;

  /// Прирост стоимости улучшения атаки за уровень
  static const int attackUpgradeCostPerLevel = 120;

  /// Максимальное количество гарантированных торговцев за уровень (0..2)
  static const int maxMerchantLevel = 2;

  /// Базовая стоимость первого уровня торговцев
  static const int merchantUpgradeCostBase = 200;

  /// Прирост стоимости улучшения торговцев за уровень
  static const int merchantUpgradeCostPerLevel = 160;

  /// Максимальный уровень навыка стартовых карт (0..5)
  static const int maxStartingCardsLevel = 5;

  /// Базовая стоимость первого уровня стартовых карт
  static const int startingCardsUpgradeCostBase = 200;

  /// Прирост стоимости улучшения стартовых карт за уровень
  static const int startingCardsUpgradeCostPerLevel = 200;

  /// Минимальное количество открытых карт в коллекции для разблокировки прокачки навыка
  static const int requiredUnlockedCardsForStartingCards = 3;

  /// Базовый шанс получить карту более высокого уровня у торговца (в %)
  static const int baseMerchantCardUpgradeChance = 5;

  /// Прирост шанса за каждый уровень улучшения (в %)
  static const int merchantCardUpgradePerLevel = 5;

  /// Максимальный уровень улучшения шанса (0..5 -> 5%..30%)
  static const int maxMerchantCardUpgradeLevel = 5;

  /// Базовая стоимость первого уровня шанса
  static const int merchantCardUpgradeCostBase = 160;

  /// Прирост стоимости улучшения шанса карт у торговца за уровень
  static const int merchantCardUpgradeCostPerLevel = 100;

  /// Базовый шанс получить золото при победе над монстром (в %)
  static const int baseMonsterGoldChance = 0;

  /// Прирост шанса золота с монстров за каждый уровень улучшения (в %)
  static const int monsterGoldPerLevel = 5;

  /// Максимальный уровень навыка золота с монстров (0..5 -> 0%..25%)
  static const int maxMonsterGoldLevel = 5;

  /// Базовая стоимость первого уровня шанса золота с монстров
  static const int monsterGoldUpgradeCostBase = 140;

  /// Прирост стоимости улучшения золота с монстров за уровень
  static const int monsterGoldUpgradeCostPerLevel = 100;

  /// Минимальное количество бонусного золота с монстра при срабатывании навыка
  static const int minMonsterGoldReward = 5;

  /// Максимальное количество бонусного золота с монстра при срабатывании навыка
  static const int maxMonsterGoldReward = 20;

  /// Базовый шанс уклонения (в %)
  static const int baseDodgeChance = 0;

  /// Прирост шанса уклонения за каждый уровень улучшения (в %)
  static const int dodgePerLevel = 2;

  /// Максимальный уровень навыка уклонения (0..10 -> 0%..20%)
  static const int maxDodgeLevel = 10;

  /// Базовая стоимость первого уровня уклонения
  static const int dodgeUpgradeCostBase = 160;

  /// Прирост стоимости улучшения уклонения за уровень
  static const int dodgeUpgradeCostPerLevel = 100;

  /// Базовый шанс сопротивления статусам (в %)
  static const int baseResistanceChance = 0;

  /// Прирост шанса сопротивления за каждый уровень улучшения (в %)
  static const int resistancePerLevel = 5;

  /// Максимальный уровень навыка сопротивления (0..5 -> 0%..25%)
  static const int maxResistanceLevel = 5;

  /// Базовая стоимость первого уровня сопротивления
  static const int resistanceUpgradeCostBase = 160;

  /// Прирост стоимости улучшения сопротивления за уровень
  static const int resistanceUpgradeCostPerLevel = 100;

  int _healthLevel = 0;
  int _attackLevel = 0;
  int _merchantLevel = 0;
  int _startingCardsLevel = 0;
  int _merchantCardUpgradeLevel = 0;
  int _monsterGoldLevel = 0;
  int _dodgeLevel = 0;
  int _resistanceLevel = 0;
  bool _loaded = false;

  /// Текущий уровень улучшения здоровья (0..10)
  int get healthLevel => _healthLevel;

  /// Текущий уровень улучшения атаки (0..10)
  int get attackLevel => _attackLevel;

  /// Текущий уровень улучшения торговцев (0..2)
  int get merchantLevel => _merchantLevel;

  /// Текущий уровень улучшения стартовых карт (0..5)
  int get startingCardsLevel => _startingCardsLevel;

  /// Текущий уровень улучшения шанса карты высшего уровня у торговца (0..5)
  int get merchantCardUpgradeLevel => _merchantCardUpgradeLevel;

  /// Текущий уровень улучшения шанса золота с монстров (0..5)
  int get monsterGoldLevel => _monsterGoldLevel;

  /// Текущий уровень улучшения уклонения (0..10)
  int get dodgeLevel => _dodgeLevel;

  /// Текущий уровень улучшения сопротивления (0..5)
  int get resistanceLevel => _resistanceLevel;

  /// Стартовое здоровье персонажа в начале игры с учётом прокачки
  int get startingHealth => baseHealth + _healthLevel * healthPerLevel;

  /// Стартовая атака персонажа в начале игры с учётом прокачки
  int get startingAttack => baseAttack + _attackLevel * attackPerLevel;

  /// Количество случайных карт, выдаваемых при старте игры (уровень 1 = 1 .. уровень 5 = 5)
  int get startingCardsCount => _startingCardsLevel;

  /// Достигнут ли максимум прокачки здоровья
  bool get isHealthMax => _healthLevel >= maxHealthLevel;

  /// Достигнут ли максимум прокачки атаки
  bool get isAttackMax => _attackLevel >= maxAttackLevel;

  /// Достигнут ли максимум прокачки торговцев
  bool get isMerchantMax => _merchantLevel >= maxMerchantLevel;

  /// Достигнут ли максимум прокачки стартовых карт
  bool get isStartingCardsMax => _startingCardsLevel >= maxStartingCardsLevel;

  /// Достигнут ли максимум прокачки шанса улучшенной карты
  bool get isMerchantCardUpgradeMax =>
      _merchantCardUpgradeLevel >= maxMerchantCardUpgradeLevel;

  /// Достигнут ли максимум прокачки золота с монстров
  bool get isMonsterGoldMax => _monsterGoldLevel >= maxMonsterGoldLevel;

  /// Достигнут ли максимум прокачки уклонения
  bool get isDodgeMax => _dodgeLevel >= maxDodgeLevel;

  /// Достигнут ли максимум прокачки сопротивления
  bool get isResistanceMax => _resistanceLevel >= maxResistanceLevel;

  /// Доступен ли навык стартовых карт для прокачки (требуется минимум 3 открытые карты)
  bool get isStartingCardsUnlocked =>
      UnlockedItemsService.instance.count >=
      requiredUnlockedCardsForStartingCards;

  /// Количество гарантированных торговцев за уровень (0 = не гарантировано)
  int get guaranteedMerchants => _merchantLevel;

  /// Итоговый шанс получить карту более высокого уровня у торговца (5..30%)
  int get merchantCardUpgradeChance =>
      (baseMerchantCardUpgradeChance +
              _merchantCardUpgradeLevel * merchantCardUpgradePerLevel)
          .clamp(5, 30);

  /// Итоговый шанс получить золото при победе над монстром (0..25%)
  int get monsterGoldChance =>
      (baseMonsterGoldChance + _monsterGoldLevel * monsterGoldPerLevel)
          .clamp(0, 25);

  /// Итоговый шанс уклонения от потери HP/атаки (0..20%)
  int get dodgeChance =>
      (baseDodgeChance + _dodgeLevel * dodgePerLevel).clamp(0, 20);

  /// Итоговый шанс сопротивления яду, кровотечению и слепоте (0..25%)
  int get resistanceChance =>
      (baseResistanceChance + _resistanceLevel * resistancePerLevel)
          .clamp(0, 25);

  /// Стоимость следующего уровня здоровья (100, 200, 300, 400...)
  int get healthUpgradeCost =>
      healthUpgradeCostBase + _healthLevel * healthUpgradeCostPerLevel;

  /// Стоимость следующего уровня атаки (120, 240, 360, 480...)
  int get attackUpgradeCost =>
      attackUpgradeCostBase + _attackLevel * attackUpgradeCostPerLevel;

  /// Стоимость следующего уровня торговцев (200, 360)
  int get merchantUpgradeCost =>
      merchantUpgradeCostBase + _merchantLevel * merchantUpgradeCostPerLevel;

  /// Стоимость следующего уровня стартовых карт (200, 400, 600, 800, 1000)
  int get startingCardsUpgradeCost =>
      startingCardsUpgradeCostBase +
      _startingCardsLevel * startingCardsUpgradeCostPerLevel;

  /// Стоимость следующего уровня шанса карт у торговца (160, 260, 360, 460, 560)
  int get merchantCardUpgradeCost =>
      merchantCardUpgradeCostBase +
      _merchantCardUpgradeLevel * merchantCardUpgradeCostPerLevel;

  /// Стоимость следующего уровня шанса золота с монстров (140, 240, 340, 440, 540)
  int get monsterGoldUpgradeCost =>
      monsterGoldUpgradeCostBase +
      _monsterGoldLevel * monsterGoldUpgradeCostPerLevel;

  /// Стоимость следующего уровня уклонения (160, 260, 360, 460, 560...)
  int get dodgeUpgradeCost =>
      dodgeUpgradeCostBase + _dodgeLevel * dodgeUpgradeCostPerLevel;

  /// Стоимость следующего уровня сопротивления (160, 260, 360, 460, 560)
  int get resistanceUpgradeCost =>
      resistanceUpgradeCostBase +
      _resistanceLevel * resistanceUpgradeCostPerLevel;

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
    _merchantCardUpgradeLevel =
        (prefs.getInt(_merchantCardUpgradeLevelKey) ?? 0).clamp(
      0,
      maxMerchantCardUpgradeLevel,
    );
    _monsterGoldLevel = (prefs.getInt(_monsterGoldLevelKey) ?? 0).clamp(
      0,
      maxMonsterGoldLevel,
    );
    _dodgeLevel = (prefs.getInt(_dodgeLevelKey) ?? 0).clamp(
      0,
      maxDodgeLevel,
    );
    _resistanceLevel = (prefs.getInt(_resistanceLevelKey) ?? 0).clamp(
      0,
      maxResistanceLevel,
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

  /// Прокачка шанса получить карту высшего уровня за монеты
  bool upgradeMerchantCardChance() {
    if (isMerchantCardUpgradeMax) return false;
    final cost = merchantCardUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _merchantCardUpgradeLevel++;
    _persistAsync();
    return true;
  }

  /// Прокачка шанса получить золото с монстров за монеты
  bool upgradeMonsterGold() {
    if (isMonsterGoldMax) return false;
    final cost = monsterGoldUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _monsterGoldLevel++;
    _persistAsync();
    return true;
  }

  /// Прокачка уклонения за монеты
  bool upgradeDodge() {
    if (isDodgeMax) return false;
    final cost = dodgeUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _dodgeLevel++;
    _persistAsync();
    return true;
  }

  /// Прокачка сопротивления за монеты
  bool upgradeResistance() {
    if (isResistanceMax) return false;
    final cost = resistanceUpgradeCost;
    final coins = PlayerCoinsService.instance.balance;
    if (coins < cost) return false;

    PlayerCoinsService.instance.applyDelta(-cost);
    _resistanceLevel++;
    _persistAsync();
    return true;
  }

  void _persistAsync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_healthLevelKey, _healthLevel);
      prefs.setInt(_attackLevelKey, _attackLevel);
      prefs.setInt(_merchantLevelKey, _merchantLevel);
      prefs.setInt(_startingCardsLevelKey, _startingCardsLevel);
      prefs.setInt(_merchantCardUpgradeLevelKey, _merchantCardUpgradeLevel);
      prefs.setInt(_monsterGoldLevelKey, _monsterGoldLevel);
      prefs.setInt(_dodgeLevelKey, _dodgeLevel);
      prefs.setInt(_resistanceLevelKey, _resistanceLevel);
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

  /// Прямая установка уровня шанса карты высшего уровня (для настроек/отладки)
  void setMerchantCardUpgradeLevel(int level) {
    _merchantCardUpgradeLevel = level.clamp(0, maxMerchantCardUpgradeLevel);
    _persistAsync();
  }

  /// Прямая установка уровня шанса золота с монстров (для настроек/отладки)
  void setMonsterGoldLevel(int level) {
    _monsterGoldLevel = level.clamp(0, maxMonsterGoldLevel);
    _persistAsync();
  }

  /// Прямая установка уровня уклонения (для настроек/отладки)
  void setDodgeLevel(int level) {
    _dodgeLevel = level.clamp(0, maxDodgeLevel);
    _persistAsync();
  }

  /// Прямая установка уровня сопротивления (для настроек/отладки)
  void setResistanceLevel(int level) {
    _resistanceLevel = level.clamp(0, maxResistanceLevel);
    _persistAsync();
  }

  /// Сброс уровней прокачки
  void resetStats() {
    _healthLevel = 0;
    _attackLevel = 0;
    _merchantLevel = 0;
    _startingCardsLevel = 0;
    _merchantCardUpgradeLevel = 0;
    _monsterGoldLevel = 0;
    _dodgeLevel = 0;
    _resistanceLevel = 0;
    _persistAsync();
  }

  /// Для тестов: сброс состояния
  void resetForTest() {
    _healthLevel = 0;
    _attackLevel = 0;
    _merchantLevel = 0;
    _startingCardsLevel = 0;
    _merchantCardUpgradeLevel = 0;
    _monsterGoldLevel = 0;
    _dodgeLevel = 0;
    _resistanceLevel = 0;
    _loaded = true;
  }

  /// Для тестов: установка уровней улучшений напрямую
  void setLevelsForTest({
    int? health,
    int? attack,
    int? merchant,
    int? startingCards,
    int? merchantCardUpgrade,
    int? monsterGold,
    int? dodge,
    int? resistance,
  }) {
    if (health != null) _healthLevel = health.clamp(0, maxHealthLevel);
    if (attack != null) _attackLevel = attack.clamp(0, maxAttackLevel);
    if (merchant != null) _merchantLevel = merchant.clamp(0, maxMerchantLevel);
    if (startingCards != null) {
      _startingCardsLevel = startingCards.clamp(0, maxStartingCardsLevel);
    }
    if (merchantCardUpgrade != null) {
      _merchantCardUpgradeLevel =
          merchantCardUpgrade.clamp(0, maxMerchantCardUpgradeLevel);
    }
    if (monsterGold != null) {
      _monsterGoldLevel = monsterGold.clamp(0, maxMonsterGoldLevel);
    }
    if (dodge != null) {
      _dodgeLevel = dodge.clamp(0, maxDodgeLevel);
    }
    if (resistance != null) {
      _resistanceLevel = resistance.clamp(0, maxResistanceLevel);
    }
    _loaded = true;
  }
}
