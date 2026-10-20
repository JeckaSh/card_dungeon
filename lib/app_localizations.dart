import 'package:flutter/material.dart';

import 'models/event_card.dart';
import 'models/item_card.dart';
import 'services/locale_service.dart';

/// Локализованные строки интерфейса приложения.
///
/// Получайте экземпляр через [AppLocalizations.of(context)] или
/// через [context.l10n] (если добавлен extension).
///
/// Поддерживаемые языки: русский (`ru`) и английский (`en`).
class AppLocalizations {
  const AppLocalizations(this._locale);

  final Locale _locale;

  bool get _isRu => _locale.languageCode == 'ru';
  bool get isRussian => _isRu;

  /// Получает локализацию из контекста, учитывая текущую локаль [LocaleService].
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(LocaleService.instance.currentLocale);
  }

  // ── Общие ────────────────────────────────────────────────────────────────
  String get appTitle => _isRu ? 'Подземелье' : 'Dungeon';
  String get appSubtitle =>
      _isRu ? 'Карточное приключение' : 'Card Adventure';
  String get back => _isRu ? 'Назад' : 'Back';
  String get close => _isRu ? 'Закрыть' : 'Close';
  String get ok => _isRu ? 'ОК' : 'OK';
  String get apply => _isRu ? 'Применить' : 'Apply';
  String get great => _isRu ? 'Отлично' : 'Great';

  // ── Главное меню ─────────────────────────────────────────────────────────
  String get menuHeroDescription =>
      _isRu
          ? 'Исследуй опасные этажи, побеждай боссов,\nсобирай реликвии и развивай своего героя!'
          : 'Explore dangerous floors, defeat bosses,\ncollect relics and develop your hero!';
  String get menuDungeon => _isRu ? 'В подземелье' : 'Enter Dungeon';
  String get menuShop => _isRu ? 'Магазин' : 'Shop';
  String get menuInventory => _isRu ? 'Инвентарь' : 'Inventory';
  String get menuQuests => _isRu ? 'Задания' : 'Quests';
  String get menuGlossary => _isRu ? 'Глоссарий' : 'Glossary';
  String get menuChronicle => _isRu ? 'Хроника' : 'Chronicle';
  String get menuTutorial => _isRu ? 'Обучение' : 'Tutorial';
  String get menuSettings => _isRu ? 'Настройки' : 'Settings';
  String get menuDebugTooltip =>
      _isRu ? 'Панель разработчика' : 'Developer Panel';

  // ── Настройки ────────────────────────────────────────────────────────────
  String get settingsTitle => _isRu ? 'Настройки' : 'Settings';
  String get settingsLanguage => _isRu ? 'Язык интерфейса' : 'Interface Language';
  String get settingsLanguageSubtitle =>
      _isRu
          ? 'Выберите язык игрового интерфейса'
          : 'Choose the game interface language';
  String get settingsLangRu => _isRu ? 'Русский' : 'Russian';
  String get settingsLangEn => _isRu ? 'Английский' : 'English';
  String get settingsLangRuNative => 'Русский';
  String get settingsLangEnNative => 'English';
  String get settingsRestartHint =>
      _isRu
          ? 'Интерфейс обновится сразу после выбора'
          : 'The interface updates immediately after selection';

  // ── Выбор подземелья ─────────────────────────────────────────────────────
  String get dungeonSelectTitle => _isRu ? 'Подземелья' : 'Dungeons';
  String get dungeonSelectSubtitle =>
      _isRu ? 'Выберите куда отправиться' : 'Choose your destination';
  String get dungeonAvailable => _isRu ? 'ДОСТУПНО' : 'AVAILABLE';
  String get dungeonSoon => _isRu ? 'СКОРО' : 'SOON';
  String get dungeonLevelsCount => _isRu ? 'Количество уровней' : 'Levels count';
  String get dungeonUniqueCards =>
      _isRu ? 'Уникальные карты' : 'Unique cards';
  String get dungeonNewCards => _isRu ? 'Новый набор карт' : 'New card set';
  String get dungeonBossEachLevel =>
      _isRu ? 'Боссы каждого уровня' : 'Boss each level';
  String get dungeonNewBosses => _isRu ? 'Новые боссы' : 'New bosses';
  String get dungeonEnterButton =>
      _isRu ? 'Войти в подземелье' : 'Enter Dungeon';
  String get dungeonInDevelopment =>
      _isRu ? 'Подземелье в разработке' : 'Dungeon in development';
  String dungeonLevels(int count) =>
      _isRu ? '$count уровня' : '$count levels';
  String dungeonName(String id, String fallback) {
    if (!_isRu) {
      if (id == 'cursed_forest') return 'Cursed Forest';
      if (id == 'catacombs') return 'Forgotten Catacombs';
    }
    return fallback;
  }
  String dungeonDescription(String id, String fallback) {
    if (!_isRu) {
      if (id == 'cursed_forest') {
        return 'A dark thicket enveloped in ancient magic and teeming with dangerous beasts. The branches whisper ominous spells, and the paths change with every step. 3 challenging levels with mighty bosses.';
      }
      if (id == 'catacombs') {
        return 'Gloomy subterranean labyrinths of a forgotten necropolis. Plague rats, bats, and skeletons lurk on the first floor. Vampires and toxic zombies await deeper below, and their monstrous empowered forms hide in the dark abyss. 3 challenging levels.';
      }
    }
    return fallback;
  }
  String dungeonScope(bool isCommon, String dungeonId, String fallback) {
    if (isCommon) return _isRu ? 'Общий' : 'Common';
    return dungeonName(dungeonId, fallback);
  }

  // ── Магазин ──────────────────────────────────────────────────────────────
  String get shopTitle => _isRu ? 'Магазин' : 'Shop';
  String get shopSubtitle =>
      _isRu ? 'Открывайте новые артефакты' : 'Unlock new artifacts';
  String get shopBalance => _isRu ? 'Баланс' : 'Balance';
  String get shopYourBalance => _isRu ? 'Ваш баланс' : 'Your balance';
  String get shopProgress => _isRu ? 'Прогресс коллекции' : 'Collection Progress';
  String get shopLootboxTitle => _isRu ? 'Лутбокс' : 'Lootbox';
  String get shopMagicChest => _isRu ? 'Магический сундук' : 'Magic Chest';
  String get shopNoviceChest => _isRu ? 'Сундук новичка' : 'Novice Chest';
  String get shopNoviceChestDesc =>
      _isRu
          ? 'Содержит базовые карты предметов 1 уровня для начинающих искателей приключений.'
          : 'Contains basic level 1 item cards for beginning adventurers.';
  String get shopNoviceChestDescAllCollected =>
      _isRu
          ? 'Все предметы новичка собраны! Сундук больше недоступен.'
          : 'All novice items collected! Chest is no longer available.';

  String get shopAdventurerChest =>
      _isRu ? 'Сундук приключенца' : 'Adventurer Chest';
  String get shopAdventurerChestDesc =>
      _isRu
          ? 'Содержит редкие карты предметов 2 уровня с мощными тактическими эффектами.'
          : 'Contains rare level 2 item cards with powerful tactical effects.';
  String get shopAdventurerChestDescAllCollected =>
      _isRu
          ? 'Все предметы приключенца собраны! Сундук больше недоступен.'
          : 'All adventurer items collected! Chest is no longer available.';

  String get shopLootboxSubtitle =>
      _isRu ? 'Случайный новый артефакт' : 'Random new artifact';
  String get shopChestDesc =>
      _isRu
          ? 'Гарантированно открывает 1 новую карту предмета для использования в подземелье.'
          : 'Guaranteed to unlock 1 new item card for use in dungeons.';
  String get shopChestCompleted =>
      _isRu
          ? 'Все доступные карты собраны! Сундук больше недоступен.'
          : 'All available cards collected! Chest is no longer available.';
  String get shopChestDescAllCollected => shopChestCompleted;
  String get shopOpenButton => _isRu ? 'Открыть' : 'Open';
  String get shopAllUnlocked =>
      _isRu ? 'Коллекция полная!' : 'Collection complete!';
  String get shopAllCardsObtained =>
      _isRu ? 'Все карты получены' : 'All cards collected';
  String shopOpenChestPrice(int price) =>
      _isRu ? 'Открыть сундук ($price 🪙)' : 'Open chest ($price 🪙)';
  String shopNotEnoughCoinsPrice(int price) =>
      _isRu ? 'Не хватает монет ($price 🪙)' : 'Not enough coins ($price 🪙)';
  String get shopNotEnoughCoins =>
      _isRu ? 'Недостаточно монет' : 'Not enough coins';
  String get shopNewCard => _isRu ? 'Новая карта!' : 'New card!';
  String get shopNewCardUnlocked =>
      _isRu ? '🎉 НОВАЯ КАРТА!' : '🎉 NEW CARD!';
  String get shopNewCardHint =>
      _isRu
          ? 'Теперь эту карту можно встретить у торговца в подземелье!'
          : 'This card can now be found at merchants in the dungeon!';
  String get shopCollection => _isRu ? 'Коллекция' : 'Collection';
  String get shopAvailableCards =>
      _isRu ? 'Доступные карты' : 'Available Cards';
  String get shopCollectionUnlocked =>
      _isRu ? 'Открыто' : 'Unlocked';
  String get shopInChest => _isRu ? 'В сундуке' : 'In chest';
  String get shopCost => _isRu ? 'Стоимость' : 'Cost';
  String get shopHeroChest => _isRu ? 'Сундук героя' : 'Hero Chest';
  String get shopHeroChestDesc =>
      _isRu
          ? 'Содержит легендарные карты предметов 3 уровня величайшей силы.'
          : 'Contains legendary level 3 item cards of immense power.';
  String get shopHeroChestDescAllCollected =>
      _isRu
          ? 'Все предметы героя собраны! Сундук больше недоступен.'
          : 'All hero items collected! Chest is no longer available.';

  // ── Валюты ────────────────────────────────────────────────────────────────
  String get currencyCoins => _isRu ? 'Монеты' : 'Coins';
  String get currencySilverKeys => _isRu ? 'Серебряные ключи' : 'Silver Keys';
  String get currencyGoldKeys => _isRu ? 'Золотые ключи' : 'Gold Keys';
  String get currencySilverKeysShort => _isRu ? 'Сер. ключи' : 'Silver Keys';
  String get currencyGoldKeysShort => _isRu ? 'Зол. ключи' : 'Gold Keys';
  String get currencyCoinsTooltip =>
      _isRu ? 'Монеты — награда за забеги и задания' : 'Coins — earned from runs and quests';
  String get currencySilverKeysTooltip =>
      _isRu ? 'Серебряные ключи — пока недоступны для получения' : 'Silver keys — not yet obtainable';
  String get currencyGoldKeysTooltip =>
      _isRu ? 'Золотые ключи — пока недоступны для получения' : 'Gold keys — not yet obtainable';

  // ── Инвентарь ────────────────────────────────────────────────────────────
  String get inventoryTitle => _isRu ? 'Инвентарь' : 'Inventory';
  String get inventoryBalance => _isRu ? 'Монеты' : 'Coins';
  String get inventoryUpgrades => _isRu ? 'Улучшения' : 'Upgrades';
  String get invCharUpgrades =>
      _isRu ? 'Прокачка персонажа' : 'Character Upgrades';
  String get invStartingStats =>
      _isRu ? 'Стартовые статы' : 'Starting Stats';
  String get inventoryHealth => _isRu ? 'Здоровье' : 'Health';
  String get inventoryAttack => _isRu ? 'Атака' : 'Attack';
  String get inventoryMerchant => _isRu ? 'Торговцы' : 'Merchants';
  String get inventoryMerchantLuck =>
      _isRu ? 'Удача торговца' : "Merchant's Luck";
  String invPerLevel(int count) =>
      _isRu ? '$count за ур.' : '$count per lvl';
  String get inventoryStartCards => _isRu ? 'Стартовые карты' : 'Starting Cards';
  String get invLocked => _isRu ? 'закрыто' : 'locked';
  String get invZeroCards => _isRu ? '0 карт' : '0 cards';
  String invCardsCount(int count) =>
      _isRu
          ? '$count ${count == 1 ? "карта" : "карты"}'
          : '$count ${count == 1 ? "card" : "cards"}';
  String invNeed3Cards(int current) =>
      _isRu ? 'Нужно 3 карты ($current/3)' : 'Need 3 cards ($current/3)';
  String get invUnlockedItemCards =>
      _isRu ? 'Открытые карты предметов' : 'Unlocked Item Cards';
  String get invCardsHint =>
      _isRu
          ? 'Эти карты могут быть куплены у торговца реликвиями в подземелье.'
          : 'These cards can be purchased from relic merchants in dungeons.';
  String get inventoryUpgrade => _isRu ? 'Улучшить' : 'Upgrade';
  String get inventoryMaxLevel => _isRu ? 'Макс' : 'Max';
  String invLvl(int level) => _isRu ? 'Ур. $level' : 'Lvl $level';
  String get invLockedCaps => _isRu ? 'ЗАБЛОКИРОВАНО' : 'LOCKED';
  String get invMaxLevelCaps => _isRu ? 'МАКС. УРОВЕНЬ' : 'MAX LEVEL';
  String get inventoryArtifacts => _isRu ? 'Артефакты' : 'Artifacts';
  String get invNoCardsUnlocked =>
      _isRu ? 'Нет открытых карт' : 'No unlocked cards';
  String get invOpenChestsHint =>
      _isRu
          ? 'Открывайте сундуки в магазине,\nчтобы разблокировать карты предметов!'
          : 'Open chests in the shop\nto unlock item cards!';
  String get inventoryNoArtifacts =>
      _isRu
          ? 'Нет открытых артефактов.\nПосетите Магазин, чтобы открыть новые!'
          : 'No unlocked artifacts.\nVisit the Shop to unlock new ones!';

  // ── Глоссарий ────────────────────────────────────────────────────────────
  String get glossaryTitle => _isRu ? 'Глоссарий' : 'Glossary';
  String get glossarySubtitle =>
      _isRu ? 'Бестиарий и энциклопедия' : 'Bestiary & Encyclopedia';
  String get glossaryCollapseAll =>
      _isRu ? 'Свернуть все' : 'Collapse all';
  String get glossaryExpandAll =>
      _isRu ? 'Развернуть все' : 'Expand all';
  String get glossaryBossHint =>
      _isRu ? 'Появляются каждую 20-ю карточку' : 'Appears every 20th card';
  String get glossaryBossBadge => _isRu ? '⚔ БОСС' : '⚔ BOSS';
  String glossaryLevel(int level) =>
      _isRu ? 'Уровень $level' : 'Level $level';
  String get glossaryUnknown => _isRu ? 'Неизвестно' : 'Unknown';
  String get glossaryMeetInDungeon =>
      _isRu ? 'Встреть в подземелье' : 'Encounter in dungeon';
  String get glossaryDiscovered =>
      _isRu ? 'Изучено' : 'Discovered';
  String bossPhaseLabel(int phase) =>
      _isRu ? 'ФАЗА $phase' : 'PHASE $phase';
  String bossMultiPhaseBadge(int count) =>
      _isRu ? 'Многофазный бой ($count фазы)' : 'Multi-phase battle ($count phases)';

  // ── Хроника ──────────────────────────────────────────────────────────────
  String get chronicleTitle => _isRu ? 'Хроника' : 'Chronicle';
  String get chronicleSubtitle =>
      _isRu ? 'История ваших походов' : 'Your run history';
  String get chronicleEmpty =>
      _isRu
          ? 'Нет сохранённых забегов.\nОтправьтесь в подземелье!'
          : 'No saved runs yet.\nEnter a dungeon!';
  String get chronicleVictory => _isRu ? 'Победа' : 'Victory';
  String get chronicleDefeat => _isRu ? 'Поражение' : 'Defeat';
  String get chronicleVictoryCaps => _isRu ? 'ПОБЕДА' : 'VICTORY';
  String get chronicleDefeatCaps => _isRu ? 'ПОРАЖЕНИЕ' : 'DEFEAT';
  String chronicleRunNumber(int num) =>
      _isRu ? 'Забег #$num' : 'Run #$num';
  String get chronicleLevelLabel => _isRu ? 'Уровень' : 'Level';
  String get chronicleCardsLabel => _isRu ? 'Карточек' : 'Cards';
  String get chronicleCoinsLabel => _isRu ? 'Монеты' : 'Coins';
  String get chronicleJournalTitle =>
      _isRu ? 'Дневник героя' : 'Hero Journal';
  String chronicleFormatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final diff = today.difference(recordDate).inDays;
    if (diff == 0) {
      return _isRu ? 'Сегодня в $h:$m' : 'Today at $h:$m';
    } else if (diff == 1) {
      return _isRu ? 'Вчера в $h:$m' : 'Yesterday at $h:$m';
    } else {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return _isRu ? '$day.$month.${dt.year} в $h:$m' : '$day.$month.${dt.year} at $h:$m';
    }
  }
  String get chronicleCoinsEarned =>
      _isRu ? 'Монеты заработаны' : 'Coins earned';
  String get chronicleCardsPlayed =>
      _isRu ? 'Карт сыграно' : 'Cards played';
  String get chronicleLog => _isRu ? 'Журнал' : 'Log';
  String get chronicleShowLog =>
      _isRu ? 'Показать журнал' : 'Show log';
  String get chronicleHideLog =>
      _isRu ? 'Скрыть журнал' : 'Hide log';

  // ── Обучение ─────────────────────────────────────────────────────────────
  String get tutorialTitle => _isRu ? 'Обучение' : 'Tutorial';
  String get tutorialExit => _isRu ? 'Выйти' : 'Exit';
  String get tutorialMentor => _isRu ? 'Наставник' : 'Mentor';
  String tutorialStep(int current, int total) =>
      _isRu ? 'Шаг $current из $total' : 'Step $current of $total';
  String tutorialInventory(int count) =>
      _isRu ? 'Инвентарь ($count)' : 'Inventory ($count)';
  String get tutorialCompleted =>
      _isRu ? 'Обучение завершено!' : 'Tutorial Complete!';
  String get tutorialCompletedBody =>
      _isRu
          ? 'Ты освоил все основы выживания в подземелье!\nТеперь ты знаешь, как делать правильные выборы, использовать артефакты и сражаться с боссами.'
          : 'You have mastered all the dungeon survival basics!\nNow you know how to make the right choices, use artifacts and fight bosses.';
  String get tutorialRewardLabel =>
      _isRu ? 'Награда за обучение' : 'Tutorial Reward';
  String get tutorialRewardCoins =>
      _isRu ? '+50 🪙 Золота' : '+50 🪙 Gold';
  String get tutorialRewardAlreadyGranted =>
      _isRu ? 'Награда уже получена ранее' : 'Reward already claimed';
  String get tutorialToMenu =>
      _isRu ? 'В главное меню' : 'Main Menu';

  // ── Игровой экран ────────────────────────────────────────────────────────
  String get gameHealth => _isRu ? 'Здоровье' : 'Health';
  String get gameAttack => _isRu ? 'Атака' : 'Attack';
  String get gameCoins => _isRu ? 'Монеты' : 'Coins';
  String get gameFloor => _isRu ? 'Этаж' : 'Floor';
  String gameDungeonFloor(int floor, int total) =>
      _isRu ? 'Этаж $floor / $total' : 'Floor $floor / $total';
  String get gameSwipeHint =>
      _isRu
          ? '← свайп влево  ·  свайп вправо →'
          : '← swipe left  ·  swipe right →';
  String get gameSurrender => _isRu ? 'Сдаться' : 'Surrender';
  String get gameSurrenderTitle => _isRu ? 'Сдаться?' : 'Surrender?';
  String gameSurrenderContent(int coins) =>
      _isRu
          ? 'При досрочном выходе из подземелья весь прогресс и накопленные за этот забег монеты ($coins 🪙) будут потеряны.'
          : 'Leaving the dungeon early will forfeit all progress and coins earned during this run ($coins 🪙).';
  String get gameSurrenderConfirm =>
      _isRu ? 'Сдаться и выйти' : 'Surrender & Exit';
  String gameBossWarning(int level) =>
      _isRu
          ? '⚔ БОСС · Уровень $level — готовься к бою!'
          : '⚔ BOSS · Level $level — prepare for battle!';
  String get gameDungeonCleared =>
      _isRu ? 'Подземелье пройдено!' : 'Dungeon Cleared!';
  String get gameAdventureOver =>
      _isRu ? 'Конец приключения' : 'Adventure Over';
  String gameVictoryCongrats(int cards, int level) =>
      _isRu
          ? 'Поздравляем! Вы успешно прошли подземелье!\nВыдержано $cards событий · Уровень $level зачищен'
          : 'Congratulations! You successfully cleared the dungeon!\nSurvived $cards events · Level $level cleared';
  String gameDefeatDesc(int cards, int level) =>
      _isRu
          ? 'Вы выдержали $cards событий!\nДобрались до уровня: $level'
          : 'You survived $cards events!\nReached level: $level';
  String get gameThisRun => _isRu ? 'За забег' : 'This Run';
  String get gameTotalCoins => _isRu ? 'Итого' : 'Total';
  String get gameRunChronicle =>
      _isRu ? 'Хроника похода' : 'Run Chronicle';
  String get gameNewRun => _isRu ? 'Новый поход' : 'New Run';
  String get gameFightAgain => _isRu ? 'Снова в бой' : 'Fight Again';
  String get gameMainMenu => _isRu ? 'В главное меню' : 'Main Menu';
  String get gameCardUsed =>
      _isRu ? 'Карта использована' : 'Card Used';
  String gameBuffShield(int charges) =>
      _isRu ? 'Щит ×$charges' : 'Shield ×$charges';
  String gameBuffDivineShield(int charges) =>
      _isRu ? 'Бож. щит ×$charges' : 'Divine Shield ×$charges';
  String gameBuffStoneskin(int turns) =>
      _isRu ? 'Каменная кожа ×$turns' : 'Stoneskin ×$turns';
  String gameBuffRegen(int turns) =>
      _isRu ? 'Регенерация ×$turns (+2❤)' : 'Regen ×$turns (+2❤)';
  String get gameBuffMirror => _isRu ? 'Зеркало' : 'Mirror';
  String get gameBuffClairvoyance =>
      _isRu ? 'Ясновидение' : 'Clairvoyance';
  String gameBuffGreed(int turns) =>
      _isRu ? 'x2 монеты ×$turns' : 'x2 coins ×$turns';
  String get gameBuffThorns => _isRu ? 'Шипы' : 'Thorns';
  String gameBuffPoison(int turns) =>
      _isRu ? 'Яд ×$turns (-1❤)' : 'Poison ×$turns (-1❤)';
  String gameBuffBleed(int turns) =>
      _isRu ? 'Кровотечение ×$turns (-2❤)' : 'Bleed ×$turns (-2❤)';
  String gameBuffBlindness(int turns) =>
      _isRu ? 'Слепота ×$turns' : 'Blindness ×$turns';
  String gameBuffMidasCurse(int turns) =>
      _isRu ? 'Проклятие Мидаса ×$turns' : 'Midas Curse ×$turns';
  String gameCardsPassed(int count) =>
      _isRu ? 'Пройдено: $count' : 'Passed: $count';
  String gameBossIn(int count) =>
      _isRu ? 'Босс через $count' : 'Boss in $count';
  String gameLevel(int level) =>
      _isRu ? 'Уровень $level' : 'Level $level';
  String gameBossBadge(int level) =>
      _isRu ? '⚔ БОСС · Уровень $level' : '⚔ BOSS · Level $level';
  String get gameNoAvailableCards =>
      _isRu ? 'Нет доступных карт' : 'No available cards';
  String gameNoResource(String res) =>
      _isRu ? 'Нет $res' : 'No $res';
  String gameNeedCoins(int amount) =>
      _isRu ? 'Нужно: $amount 🪙' : 'Need: $amount 🪙';
  String gameNeedAttack(int amount) =>
      _isRu ? 'Нужно: $amount ⚡' : 'Need: $amount ⚡';
  String get gameAddCardBag =>
      _isRu ? '🎒 +1 карта' : '🎒 +1 card';
  String get gameVictory => _isRu ? 'Победа!' : 'Victory!';
  String get gameDefeat => _isRu ? 'Поражение' : 'Defeat';
  String get gameToMenu => _isRu ? 'В меню' : 'Menu';
  String get gameContinue => _isRu ? 'Продолжить' : 'Continue';
  String statusEffectLabel(StatusEffectType type) {
    if (!_isRu) {
      return switch (type) {
        StatusEffectType.poison => 'Poison',
        StatusEffectType.bleed => 'Bleed',
        StatusEffectType.blindness => 'Blindness',
        StatusEffectType.midasCurse => 'Midas Curse',
      };
    }
    return type.label;
  }

  // ── Листы предметов и инвентаря ──────────────────────────────────────────
  String get invSheetTitle =>
      _isRu ? 'Инвентарь забега' : 'Run Inventory';
  String invSheetItemCount(int count) =>
      _isRu ? 'Предметов: $count' : 'Items: $count';
  String get invSheetEmpty =>
      _isRu ? 'Рюкзак пуст' : 'Backpack is empty';
  String get invSheetEmptyHint =>
      _isRu
          ? 'Покупайте зелья и свитки у торговца реликвиями во время приключения!'
          : 'Buy potions and scrolls from relic merchants during your adventure!';
  String get invSheetApply => _isRu ? 'Применить' : 'Use';
  String get itemDetailsUnlocked => _isRu ? 'Открыта' : 'Unlocked';
  String get itemDetailsInChest => _isRu ? 'В сундуке' : 'In chest';
  String get itemDetailsUnlockedHint =>
      _isRu
          ? 'Эта карта разблокирована и может быть куплена у торговца реликвиями в подземелье.'
          : 'This card is unlocked and can be purchased from relic merchants in the dungeon.';
  String get itemDetailsLockedHint =>
      _isRu
          ? 'Эта карта пока не открыта. Открывайте магические сундуки в магазине, чтобы разблокировать её!'
          : 'This card is not yet unlocked. Open magic chests in the shop to unlock it!';

  // ── Названия и эффекты карт предметов ────────────────────────────────────
  String itemTitle(String id, String fallback) {
    if (!_isRu) {
      return switch (id) {
        'potion_heal' => 'Healing Potion',
        'potion_attack' => 'Attack Potion',
        'elixir_attack' => 'Attack Elixir',
        'scroll_skip' => 'Turn Skip',
        'elixir_life' => 'Elixir of Life',
        'runic_shield' => 'Runic Shield',
        'mirror_distortion' => 'Mirror of Distortion',
        'thornmail' => 'Thornmail',
        'philosophers_stone' => 'Philosopher\'s Stone',
        'shadow_pact' => 'Shadow Pact',
        'greed_magnet' => 'Greed Magnet',
        'dice_of_fate' => 'Dice of Fate',
        'smoke_bomb' => 'Smoke Bomb',
        'gold_bribe' => 'Golden Bribe',
        _ => fallback,
      };
    }
    return fallback;
  }

  String itemDescription(String id, String fallback) {
    if (!_isRu) {
      return switch (id) {
        'potion_heal' => 'Restores +4 health',
        'potion_attack' => 'Increases attack by +4',
        'elixir_attack' => 'Increases attack by +8',
        'scroll_skip' => 'Skips current card without consequences',
        'elixir_life' => 'Restores +8 health',
        'runic_shield' => 'Next incoming health damage will be fully absorbed.',
        'mirror_distortion' => 'Next turn: all losses turn into equal gains.',
        'thornmail' => 'Next hit: converts damage into double gold.',
        'philosophers_stone' => 'Converts coins (×10, max 50🪙) into attack (+1) and health (+2).',
        'shadow_pact' => 'Sacrifice half HP → double coins + random card.',
        'greed_magnet' => 'Doubles all coins gained in events for 3 turns.',
        'dice_of_fate' => 'Random outcome: losses, an artifact, or jackpot (+5❤ +2⚡ +25🪙).',
        'smoke_bomb' => 'Instant escape: card is skipped, best coins are kept.',
        'gold_bribe' => 'Spend 15🪙 to choose the best outcome without consequences.',
        _ => fallback,
      };
    }
    return fallback;
  }

  String itemCategoryLabel(ItemEffectType type) {
    if (!_isRu) {
      return switch (type) {
        ItemEffectType.heal => 'Healing',
        ItemEffectType.attack => 'Buff',
        ItemEffectType.skip => 'Scroll',
        ItemEffectType.shield => 'Defense',
        ItemEffectType.invertNext => 'Distortion',
        ItemEffectType.thornmail => 'Counter',
        ItemEffectType.transmute => 'Alchemy',
        ItemEffectType.shadowPact => 'Dark Pact',
        ItemEffectType.greedMagnet => 'Economy',
        ItemEffectType.diceOfFate => 'Luck',
        ItemEffectType.smokeBomb => 'Escape',
        ItemEffectType.bribery => 'Diplomacy',
        ItemEffectType.divineShield => 'Defense',
        ItemEffectType.stoneskin => 'Defense',
        ItemEffectType.antidote => 'Cleanse',
        ItemEffectType.regeneration => 'Healing',
        ItemEffectType.teleport => 'Scroll',
      };
    }
    return type.categoryLabel;
  }

  String itemEffectBadge(ItemEffectType type, int value) {
    if (!_isRu) {
      return switch (type) {
        ItemEffectType.heal => '+$value ❤',
        ItemEffectType.attack => '+$value ⚡',
        ItemEffectType.skip => 'Skip',
        ItemEffectType.shield => '🛡️ 50%',
        ItemEffectType.invertNext => '🪞 Inversion',
        ItemEffectType.thornmail => '🌵 Thorns',
        ItemEffectType.transmute => '⚗️ Alchemy',
        ItemEffectType.shadowPact => '📜 Pact',
        ItemEffectType.greedMagnet => '🧲 x2 Coins',
        ItemEffectType.diceOfFate => '🎲 Dice',
        ItemEffectType.smokeBomb => '💨 Escape',
        ItemEffectType.bribery => '💰 Bribe',
        ItemEffectType.divineShield => '✨🛡️ 100%',
        ItemEffectType.stoneskin => '🪨 Stoneskin',
        ItemEffectType.antidote => '🧪 Antidote',
        ItemEffectType.regeneration => '🌿 +2❤/turn',
        ItemEffectType.teleport => '🌀 1-3 cards',
      };
    }
    return type.getBadge(value);
  }

  // ── Типы событий ─────────────────────────────────────────────────────────
  String get eventTypeMonster => _isRu ? 'Монстры' : 'Monsters';
  String get eventTypeMerchant => _isRu ? 'Торговцы' : 'Merchants';
  String get eventTypeEvent => _isRu ? 'События' : 'Events';
  String get eventTypeBoss => _isRu ? 'Боссы' : 'Bosses';
  String get eventTypeTrap => _isRu ? 'Ловушки' : 'Traps';
  String get eventTypeTreasure => _isRu ? 'Сокровища' : 'Treasures';
  String get eventTypeHeal => _isRu ? 'Лечение' : 'Healing';
  String get eventTypeRelic => _isRu ? 'Реликвии' : 'Relics';

  String eventTypeLabel(EventType type) {
    if (!_isRu) {
      return switch (type) {
        EventType.monster => 'Monster',
        EventType.trap => 'Trap',
        EventType.treasure => 'Treasure',
        EventType.merchant => 'Merchant',
        EventType.rest => 'Rest',
        EventType.mystery => 'Mystery',
        EventType.boss => 'BOSS',
      };
    }
    return switch (type) {
      EventType.monster => 'Монстр',
      EventType.trap => 'Ловушка',
      EventType.treasure => 'Сокровище',
      EventType.merchant => 'Торговец',
      EventType.rest => 'Привал',
      EventType.mystery => 'Тайна',
      EventType.boss => 'БОСС',
    };
  }

  String eventTypePluralLabel(EventType type) {
    if (!_isRu) {
      return switch (type) {
        EventType.monster => 'Monsters',
        EventType.trap => 'Traps',
        EventType.treasure => 'Treasures',
        EventType.merchant => 'Merchants',
        EventType.rest => 'Rests',
        EventType.mystery => 'Mysteries',
        EventType.boss => 'Bosses',
      };
    }
    return switch (type) {
      EventType.monster => 'Монстры',
      EventType.trap => 'Ловушки',
      EventType.treasure => 'Сокровища',
      EventType.merchant => 'Торговцы',
      EventType.rest => 'Привалы',
      EventType.mystery => 'Тайны',
      EventType.boss => 'Боссы',
    };
  }

  // ── Отладочный экран ─────────────────────────────────────────────────────
  String get debugTitle => _isRu ? 'Панель отладки' : 'Debug Panel';
  String get debugEventsTitle => _isRu ? 'Карточки событий' : 'Event Cards';
  String debugUnlockedCount(int count, int total) =>
      _isRu ? 'Открыто: $count / $total' : 'Unlocked: $count / $total';
  String get debugUnlockAll => _isRu ? 'Открыть все' : 'Unlock All';
  String get debugLockAll => _isRu ? 'Закрыть все' : 'Lock All';
  String get debugItemsTitle =>
      _isRu ? 'Карточки предметов (лутбоксы)' : 'Item Cards (Lootboxes)';
  String get debugCoinsTitle => _isRu ? 'Монеты' : 'Coins';
  String debugCoinsBalance(int balance) =>
      _isRu ? 'Баланс: $balance 🪙' : 'Balance: $balance 🪙';
  String get debugResetCoins => _isRu ? 'Обнулить' : 'Reset to 0';
  String get debugSetCoinsLabel =>
      _isRu ? 'Установить баланс' : 'Set balance';
  String get debugApply => _isRu ? 'Применить' : 'Apply';
  String get debugKeysTitle => _isRu ? 'Ключи (валюты)' : 'Keys (Currencies)';
  String debugSilverKeysBalance(int count) =>
      _isRu ? 'Серебряные ключи: $count 🗝️' : 'Silver keys: $count 🗝️';
  String debugGoldKeysBalance(int count) =>
      _isRu ? 'Золотые ключи: $count 🔑' : 'Gold keys: $count 🔑';
  String get debugHeroStatsTitle =>
      _isRu ? 'Прокачка характеристик героя' : 'Hero Stat Upgrades';
  String debugHeroStatsSubtitle({
    required int healthLvl,
    required int startingHealth,
    required int attackLvl,
    required int startingAttack,
    required int merchantLvl,
    required int cardsLvl,
    required int cardsCount,
  }) =>
      _isRu
          ? 'Здоровье: ур. $healthLvl ($startingHealth ❤) • Атака: ур. $attackLvl ($startingAttack ⚡) • Торговцы: ур. $merchantLvl • Карты: ур. $cardsLvl ($cardsCount шт.)'
          : 'Health: lvl $healthLvl ($startingHealth ❤) • Attack: lvl $attackLvl ($startingAttack ⚡) • Merchants: lvl $merchantLvl • Cards: lvl $cardsLvl ($cardsCount pcs)';
  String get debugHealthLevelTitle =>
      _isRu ? 'Уровень здоровья' : 'Health Level';
  String get debugAttackLevelTitle =>
      _isRu ? 'Уровень атаки' : 'Attack Level';
  String get debugMerchantLevelTitle =>
      _isRu ? 'Уровень торговцев' : 'Merchants Level';
  String get debugStartingCardsLevelTitle =>
      _isRu ? 'Уровень стартовых карт' : 'Starting Cards Level';
  String debugStartBonus(String startVal, String bonusVal) =>
      _isRu ? 'Старт: $startVal ($bonusVal)' : 'Start: $startVal ($bonusVal)';
  String debugLevelMax(int level, int max) =>
      _isRu ? 'Ур. $level / $max' : 'Lvl $level / $max';
  String get debugLevelMinChip => _isRu ? 'Мин (0)' : 'Min (0)';
  String debugLevelChip(int lvl) => _isRu ? 'Ур. $lvl' : 'Lvl $lvl';
  String debugLevelMaxChip(int max) =>
      _isRu ? 'Макс ($max)' : 'Max ($max)';
  String get debugRandom => _isRu ? 'случайно' : 'random';
  String debugMerchantsPerLevel(int count) =>
      _isRu ? '$count 🏪 за уровень' : '$count 🏪 per level';
  String get debugNoGuarantee =>
      _isRu ? 'нет гарантии' : 'no guarantee';
  String debugMerchantsGuaranteed(int count) =>
      _isRu ? '$count торг. гарант.' : '$count merch. guaranteed';
  String get debugNoCards => _isRu ? 'нет карт' : 'no cards';
  String debugCardsAtStart(int count) =>
      _isRu ? '$count карт на старте' : '$count cards at start';
  String get debugZeroCards => _isRu ? '0 карт' : '0 cards';
  String debugRandomCardsBonus(int count) =>
      _isRu ? '+$count случ. карт' : '+$count random cards';
  String get debugResetStats => _isRu ? 'Сбросить в 0' : 'Reset to 0';
  String get debugMaxStats =>
      _isRu ? 'Максимум (10/10/2/3)' : 'Max (10/10/2/3)';
  String get debugChronicleTitle =>
      _isRu ? 'Хроника забегов' : 'Run Chronicle';
  String debugChronicleRecords(int count, int max) =>
      _isRu ? 'Записей: $count / $max' : 'Records: $count / $max';
  String get debugClearChronicle =>
      _isRu ? 'Очистить хронику' : 'Clear Chronicle';

  // ── Задания и Ежедневные награды ─────────────────────────────────────────
  String get questsTitle => _isRu ? 'Задания' : 'Quests';
  String get questsSubtitle =>
      _isRu ? 'Ежедневные награды и серия входов' : 'Daily rewards and login streak';
  String get questsDailySection =>
      _isRu ? 'Ежедневный вход' : 'Daily Login';
  String get questsWeeklyStreak =>
      _isRu ? 'Серия входов (7 дней)' : 'Login Streak (7 Days)';
  String questsStreakProgress(int current, int total) =>
      _isRu ? 'День $current из $total' : 'Day $current of $total';
  String get dailyResetNote =>
      _isRu ? 'Смена дня в 00:00 по МСК (UTC+3)' : 'Day resets at 00:00 MSK (UTC+3)';
  String dailyNextResetIn(String time) =>
      _isRu ? 'До обновления: $time' : 'Resets in: $time';
  String get dailyRewardTitle =>
      _isRu ? 'Награда за вход' : 'Daily Login Reward';
  String get dailyRewardSubtitle =>
      _isRu
          ? 'Заходите в игру каждый день, чтобы увеличивать награду!'
          : 'Log in daily to increase your rewards!';
  String dailyRewardDayNumber(int day) =>
      _isRu ? 'День $day' : 'Day $day';
  String dailyRewardCoinsAmount(int amount) =>
      _isRu ? '+$amount монет' : '+$amount coins';
  String get dailyRewardClaimButton =>
      _isRu ? 'Забрать награду' : 'Claim Reward';
  String get dailyRewardClaimedStatus =>
      _isRu ? 'Получено' : 'Claimed';
  String get dailyRewardClaimedToday =>
      _isRu ? 'Получено сегодня' : 'Claimed today';
  String get dailyRewardLocked =>
      _isRu ? 'Заблокировано' : 'Locked';
  String get dailyRewardJackpotBadge =>
      _isRu ? 'Супернаграда 👑' : 'Grand Prize 👑';
  String dailyRewardReceivedMessage(int amount) =>
      _isRu ? 'Получено $amount монет!' : 'Received $amount coins!';
  String get dailyRewardResetAfterSeven =>
      _isRu
          ? 'После 7-го дня счётчик начнётся заново с 1-го дня.'
          : 'After day 7, the streak restarts from day 1.';
  String get dailyRewardRollbackDetected =>
      _isRu
          ? 'Обнаружен перевод времени назад. Пожалуйста, восстановите правильное время на устройстве.'
          : 'Time rollback detected. Please restore the correct time on your device.';
  String get dailyRewardNeedInternet =>
      _isRu
          ? 'Требуется подключение к интернету для проверки мирового времени.'
          : 'Internet connection is required to verify world time.';
  String get dailyRewardSyncTimeButton =>
      _isRu ? 'Проверить время' : 'Sync Time';
  String get dailyRewardSyncing =>
      _isRu ? 'Синхронизация времени...' : 'Synchronizing time...';
  String get questsUpcomingTitle =>
      _isRu ? 'Задания подземелья' : 'Dungeon Quests';
  String get questsUpcomingDesc =>
      _isRu
          ? 'Скоро здесь появятся новые испытания с ценными наградами!'
          : 'New dungeon challenges with valuable rewards are coming soon!';
  String get questsComingSoonBadge =>
      _isRu ? 'Скоро' : 'Coming Soon';

  // ── Ежедневные задания ───────────────────────────────────────────────────
  String get dailyQuestsSection =>
      _isRu ? 'Ежедневные задания' : 'Daily Quests';
  String get dailyQuestsSubtitle =>
      _isRu
          ? 'Выполняйте задания каждый день и получайте монеты'
          : 'Complete daily quests to earn bonus coins';

  String questPlayDungeonsTitle(int count) {
    if (_isRu) {
      if (count % 10 == 1 && count % 100 != 11) return 'Сыграть $count подземелье';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
        return 'Сыграть $count подземелья';
      }
      return 'Сыграть $count подземелий';
    }
    return 'Play $count ${count == 1 ? "dungeon" : "dungeons"}';
  }

  String get questPlayDungeonsDesc =>
      _isRu
          ? 'Завершите забег победой или поражением'
          : 'Finish a run by victory or defeat';

  String questPlaySpecificDungeonTitle(int count, String dungeonName) {
    if (_isRu) {
      if (count % 10 == 1 && count % 100 != 11) return 'Сыграть в «$dungeonName» $count раз';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
        return 'Сыграть в «$dungeonName» $count раза';
      }
      return 'Сыграть в «$dungeonName» $count раз';
    }
    return 'Play "$dungeonName" $count ${count == 1 ? "time" : "times"}';
  }

  String get questPlaySpecificDungeonDesc =>
      _isRu
          ? 'Завершите забег в указанном подземелье победой или поражением'
          : 'Finish a run in the specified dungeon by victory or defeat';

  String questKillBossesTitle(int count) {
    if (_isRu) {
      if (count % 10 == 1 && count % 100 != 11) return 'Убить $count босса';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
        return 'Убить $count босса';
      }
      return 'Убить $count боссов';
    }
    return 'Defeat $count ${count == 1 ? "boss" : "bosses"}';
  }

  String get questKillBossesDesc =>
      _isRu
          ? 'Одолейте боссов на этажах подземелий'
          : 'Defeat bosses on dungeon floors';

  String questClearDungeonTitle([int count = 1]) {
    if (_isRu) {
      if (count == 1) return 'Пройти 1 подземелье';
      if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
        return 'Пройти $count подземелья';
      }
      return 'Пройти $count подземелий';
    }
    return 'Complete $count ${count == 1 ? "dungeon" : "dungeons"}';
  }

  String get questClearDungeonDesc =>
      _isRu
          ? 'Одержите полную победу в любом подземелье'
          : 'Achieve complete victory in any dungeon';

  // ── Еженедельные задания ─────────────────────────────────────────────────
  String get weeklyQuestsSection =>
      _isRu ? 'Еженедельные задания' : 'Weekly Quests';
  String get weeklyQuestsSubtitle =>
      _isRu
          ? 'Сложные испытания недели — по 500 монет за каждое'
          : 'Challenging weekly quests — 500 coins each';
  String get weeklyResetNote =>
      _isRu
          ? 'Сброс каждый понедельник в 00:00 (МСК)'
          : 'Resets every Monday at 00:00 (MSK)';

  String weeklyTimeRemaining(Duration d) {
    if (d.inDays > 0) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      if (_isRu) {
        return '$days д. $hours ч.';
      }
      return '${days}d ${hours}h';
    }
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String questEncounterCardsTitle(int count, EventType? type) {
    final typeName = questEventTypeName(type);
    if (_isRu) {
      return 'Встретить $count карт: $typeName';
    }
    return 'Encounter $count $typeName cards';
  }

  String get questEncounterCardsDesc =>
      _isRu
          ? 'Исследуйте подземелья и открывайте карты'
          : 'Explore dungeons and encounter cards';

  String questEventTypeName(EventType? type) {
    if (type == null) return _isRu ? 'Любые' : 'Any';
    switch (type) {
      case EventType.monster:
        return _isRu ? 'Монстры' : 'Monsters';
      case EventType.trap:
        return _isRu ? 'Ловушки' : 'Traps';
      case EventType.treasure:
        return _isRu ? 'Сокровища' : 'Treasures';
      case EventType.merchant:
        return _isRu ? 'Торговцы' : 'Merchants';
      case EventType.rest:
        return _isRu ? 'Привалы' : 'Rest Sites';
      case EventType.mystery:
        return _isRu ? 'Тайны' : 'Mysteries';
      case EventType.boss:
        return _isRu ? 'Боссы' : 'Bosses';
    }
  }

  String questProgressText(int current, int total) => '$current / $total';
  String questRewardBadgeText(int amount) => '+$amount 🪙';
  String questClaimButtonText(int amount) =>
      _isRu ? 'Забрать (+$amount 🪙)' : 'Claim (+$amount 🪙)';
  String get questClaimedBadgeText =>
      _isRu ? 'Получено' : 'Claimed';
  String get questInProgressBadgeText =>
      _isRu ? 'В процессе' : 'In Progress';
  String questCompletedNotification(int amount) =>
      _isRu ? 'Задание выполнено! Получено +$amount монет!' : 'Quest completed! Received +$amount coins!';

  // ── Бонусы за выполнение всех заданий (ключи) ─────────────────────────────
  String get questsAllDailyBonusTitle =>
      _isRu ? 'Награда за все задания дня' : 'All Daily Quests Reward';
  String get questsAllDailyBonusDesc =>
      _isRu
          ? 'Выполните все задания дня и заберите серебряные ключи'
          : 'Complete all daily quests to get silver keys';
  String questsAllDailyBonusClaim(int count) =>
      _isRu ? 'Забрать бонус (+$count 🗝️)' : 'Claim Bonus (+$count 🗝️)';
  String get questsAllDailyBonusClaimed =>
      _isRu ? 'Бонус получен (+2 🗝️)' : 'Bonus Claimed (+2 🗝️)';

  String get questsAllWeeklyBonusTitle =>
      _isRu ? 'Награда за все задания недели' : 'All Weekly Quests Reward';
  String get questsAllWeeklyBonusDesc =>
      _isRu
          ? 'Выполните все задания недели и заберите золотые ключи'
          : 'Complete all weekly quests to get gold keys';
  String questsAllWeeklyBonusClaim(int count) =>
      _isRu ? 'Забрать супер-бонус (+$count 🔑)' : 'Claim Grand Bonus (+$count 🔑)';
  String get questsAllWeeklyBonusClaimed =>
      _isRu ? 'Супер-бонус получен (+2 🔑)' : 'Grand Bonus Claimed (+2 🔑)';

  // ── Дебаг ежедневных наград и заданий ─────────────────────────────────────
  String get debugDailyTitle =>
      _isRu ? 'Ежедневные награды (стрик)' : 'Daily Rewards (Streak)';
  String get debugDailyResetToday =>
      _isRu ? 'Сбросить получение за сегодня' : 'Reset today\'s claim';
  String get debugDailyResetAll =>
      _isRu ? 'Сбросить весь стрик' : 'Reset whole streak';
  String debugDailySetStreak(int day) =>
      _isRu ? 'Установить день $day' : 'Set day $day';

  String get debugQuestsTitle =>
      _isRu ? 'Ежедневные задания' : 'Daily Quests';
  String get debugQuestsCompleteAll =>
      _isRu ? 'Выполнить задания' : 'Complete all quests';
  String get debugQuestsReroll =>
      _isRu ? 'Сгенерировать новые' : 'Reroll quests';
  String get debugQuestsReset =>
      _isRu ? 'Сбросить прогресс' : 'Reset progress';
}

/// Удобный extension для доступа к локализации из [BuildContext].
extension AppLocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
