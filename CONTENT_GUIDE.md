# 📖 Руководство разработчика по архитектуре и контенту Card Dungeon

Данное руководство содержит полное описание архитектуры проекта, механизма игрового цикла и пошаговые инструкции по добавлению любого нового контента: карт событий, боссов, расходуемых предметов (артефактов), новых подземелий и настроек баланса.

---

## 📑 Содержание
1. [Архитектура проекта](#1-архитектура-проекта)
2. [Игровой цикл и механики](#2-игровой-цикл-и-механики)
3. [Как добавить новую карту события](#3-как-добавить-новую-карту-события)
4. [Как добавить нового босса](#4-как-добавить-нового-босса)
5. [Как добавить новое подземелье](#5-как-добавить-новое-подземелье)
6. [Как добавить новый расходуемый предмет (артефакт)](#6-как-добавить-новый-расходуемый-предмет-артефакт)
7. [Настройка прокачки и баланса](#7-настройка-прокачки-и-баланса)
8. [Инструменты тестирования и отладки](#8-инструменты-тестирования-и-отладки)

---

## 1. Архитектура проекта

Проект построен по модульному data-driven принципу Flutter:

```
lib/
├── main.dart                  # Точка входа, инициализация темы и ориентации
├── models/                    # Модели данных
│   ├── dungeon.dart           # Модель подземелья (Dungeon)
│   ├── event_card.dart        # Модели карты события (EventCard), выбора (CardChoice), статусов
│   └── item_card.dart         # Модель расходуемого предмета (ItemCard) и типы эффектов
├── data/                      # Реестры контента (чистые const-данные)
│   ├── dungeons.dart          # Список подземелий (allDungeons)
│   ├── events.dart            # Список всех карт событий (allEvents) и боссов (allBossCards)
│   ├── items.dart             # Каталог предметов (allItemCards) и генераторы случайных карт
│   └── legacy_events.dart     # Архив прежних карт
├── services/                  # Сервисы постоянного хранения (SharedPreferences)
│   ├── player_coins_service.dart   # Баланс золота игрока
│   ├── player_stats_service.dart   # Прокачка здоровья, атаки, торговцев, стартовых карт
│   ├── unlocked_items_service.dart # Реестр открытых карт предметов
│   ├── discovered_events.dart      # Реестр открытых событий для Глоссария
│   └── run_chronicle_service.dart  # История последних 10 забегов и дневник
├── screens/                   # Экраны приложения
│   ├── menu_screen.dart           # Главное меню
│   ├── dungeon_select_screen.dart # Выбор подземелья
│   ├── game_screen.dart           # Основной игровой экран (рогалик)
│   ├── shop_screen.dart           # Магазин открытия новых карт за монеты
│   ├── inventory_screen.dart      # Инвентарь и прокачка характеристик
│   ├── glossary_screen.dart       # Бестиарий / энциклопедия карт
│   ├── chronicle_screen.dart      # Хроника завершённых походов
│   └── debug_screen.dart          # Меню разработчика / читы / тесты
├── widgets/                   # Переиспользуемые UI-компоненты
│   ├── swipe_card.dart        # Интерактивная карта со свайпом
│   ├── stats_bar.dart         # Верхняя панель здоровья, атаки, монет и босса
│   ├── inventory_sheet.dart   # Нижний лист инвентаря во время боя
│   ├── item_card_widget.dart  # Карточка предмета для магазина и инвентаря
│   ├── item_details_sheet.dart# Детальный просмотр предмета
│   └── glossary_card.dart     # Карточка события в глоссарии
└── utils/
    └── event_style.dart       # Цвета, иконки и текстовые названия категорий событий
```

---

## 2. Игровой цикл и механики

### 2.1. Формирование колоды этажа
1. В начале забега или при переходе на новый этаж вызывается `_rebuildDeck()` в [game_screen.dart](file:///i:/dev/card_dungeon/lib/screens/game_screen.dart).
2. Из `allEvents` отбираются карты, у которых:
   - `level == currentDungeonLevel`;
   - `isAvailableInDungeon(currentDungeon.id)` (подходят для текущего подземелья либо имеют `dungeonId: DungeonId.common`).
3. Карты перемешиваются (`shuffle`).
4. Если у игрока прокачан навык «Гарантированные торговцы» (`PlayerStatsService.guaranteedMerchants > 0`), в первые 19 карт гарантированно вставляется указанное количество карт торговцев.

### 2.2. Появление босса
- Каждая 20-я карта забега (`(cardsPassed + 1) % 20 == 0`) является **боссом**.
- Босс выбирается из `allBossCards` для текущего подземелья.
- Победа над боссом:
  - Если есть следующий этаж (`level + 1 <= dungeon.levelsCount`), уровень увеличивается, пересобирается колода следующего этажа.
  - Если этажи закончились — наступает **Победа** (`GameResult.victory`), золото зачисляется на общий баланс, забег пишется в Хронику.

### 2.3. Механика свайпа и расчет урона
- **Свайп влево** активирует `leftChoice`, **вправо** — `rightChoice`.
- Если выбор требует монет (`coinsDelta < 0`) или атаки (`attackDelta < 0`), а у игрока их меньше нужного, свайп **блокируется** и карта возвращается на место.
- Порядок применения модификаторов к выбору:
  1. **Проклятие Мидаса**: если активно, полученные монеты обнуляются.
  2. **Зеркало искажения**: если активно, любые отрицательные дельты обращаются в положительные.
  3. **Рунический щит**: если входящий урон по здоровью `< 0`, щит тратит 1 заряд и полностью поглощает урон.
  4. **Шипованная броня**: если получен урон, герой получает `|урон| * 2` золота.
  5. **Магнит жадности**: удваивает полученное золото.
  6. **Статусы (DoT)**: наложение шансовых статусов (яд, кровотечение, слепота, проклятие) и вычитание периодического урона от уже активных статусов.

---

## 3. Как добавить новую карту события

Все карты событий хранятся в [lib/data/events.dart](file:///i:/dev/card_dungeon/lib/data/events.dart) в списке `allEvents`.

### 3.1. Типы событий (`EventType`):
- `EventType.monster` — монстры и противники;
- `EventType.trap` — ловушки и преграды;
- `EventType.treasure` — сокровища и клады;
- `EventType.merchant` — торговцы;
- `EventType.rest` — лагерь, святилище, исцеление;
- `EventType.mystery` — алтари, загадки, магия.

### 3.2. Доступные статусы (`StatusEffectType`):
- `StatusEffectType.poison` — яд (-1 HP на 3 хода);
- `StatusEffectType.bleed` — кровотечение (-2 HP на 3 хода);
- `StatusEffectType.blindness` — скрывает текст эффектов на 3 хода;
- `StatusEffectType.midasCurse` — всё получаемое золото обращается в 0 на 3 хода.

### 3.3. Пример добавления карты:
```dart
EventCard(
  id: 'forest_ancient_shrine',            // Уникальный ID (будет в глоссарии)
  type: EventType.mystery,                // Категория
  title: 'Древнее святилище',             // Название
  description:
      'Среди мшистых камней мерцает рунический алтарь. Воздух вокруг дрожит от магии.',
  leftChoice: CardChoice(
    label: 'Возложить монеты',
    coinsDelta: -10,                      // Спишет 10 монет (заблокировано, если < 10)
    healthDelta: 4,                       // Даст +4 HP
    givesRandomItem: true,                // Выдаст случайную открытую карту предмета
  ),
  rightChoice: CardChoice(
    label: 'Осквернить алтарь',
    coinsDelta: 20,                       // Награда 20 монет
    attackDelta: 1,                       // +1 к атаке
    statusEffect: StatusEffectType.poison,// 50% шанс получить отравление
    statusChance: 0.5,
  ),
  level: 1,                               // Этаж подземелья (1, 2 или 3)
  dungeonId: DungeonId.cursedForest,      // Или DungeonId.common для всех подземелий
),
```

---

## 4. Как добавить нового босса

Боссы хранятся в [lib/data/events.dart](file:///i:/dev/card_dungeon/lib/data/events.dart) в списке `allBossCards`.

### Особенности боссов:
- `type: EventType.boss` — обязательно;
- `level` — номер этажа, в конце которого появляется данный босс;
- `dungeonId` — идентификатор подземелья, в котором босс обитает.

### Пример добавления босса:
```dart
EventCard(
  id: 'forest_boss_ancient_ent',
  type: EventType.boss,
  title: 'Древний Древобород',
  description:
      'Исполинский оживший дуб преграждает путь к сердцу чащи. Его корни крушат камень, а кора тверда как гранит.',
  leftChoice: CardChoice(
    label: 'Срубить корни',
    healthDelta: -4,
    attackDelta: 2,
    coinsDelta: 25,
  ),
  rightChoice: CardChoice(
    label: 'Сжечь ветви',
    attackDelta: -2,
    coinsDelta: 35,
  ),
  level: 2,                               // Босс 2-го этажа
  dungeonId: DungeonId.cursedForest,
),
```

---

## 5. Как добавить новое подземелье

Чтобы добавить полностью новую локацию:

### Шаг 1. Добавьте идентификатор в `DungeonId`
В [lib/models/event_card.dart](file:///i:/dev/card_dungeon/lib/models/event_card.dart):
```dart
class DungeonId {
  static const String common = 'common';
  static const String cursedForest = 'cursed_forest';
  static const String catacombs = 'catacombs'; // <-- Новый ID
  
  static String getLabel(String id) {
    if (isCommon(id)) return 'Общий';
    if (id == cursedForest) return 'Проклятый лес';
    if (id == catacombs) return 'Катакомбы';   // <-- Название
    return id;
  }
}
```

### Шаг 2. Зарегистрируйте объект `Dungeon`
В [lib/data/dungeons.dart](file:///i:/dev/card_dungeon/lib/data/dungeons.dart):
```dart
const Dungeon catacombsDungeon = Dungeon(
  id: DungeonId.catacombs,
  name: 'Заброшенные катакомбы',
  description: 'Древние склепы, кишащие нежитью и ловушками.',
  levelsCount: 3,                         // Количество этажей
  icon: Icons.castle_rounded,             // Иконка
  accentColor: Color(0xFF9C27B0),         // Цвет темы
  isAvailable: true,                      // true = открыто для выбора
);

// Добавьте в список:
const List<Dungeon> allDungeons = [
  cursedForestDungeon,
  catacombsDungeon,
];
```

### Шаг 3. Наполните подземелье событиями и боссами
В [lib/data/events.dart](file:///i:/dev/card_dungeon/lib/data/events.dart):
1. Добавьте события с `dungeonId: DungeonId.catacombs` для уровней 1, 2, 3.
2. Добавьте боссов для каждого уровня (1, 2, 3) в `allBossCards` с `dungeonId: DungeonId.catacombs`.

---

## 6. Как добавить новый расходуемый предмет (артефакт)

Предметы используются из инвентаря во время забега.

### Шаг 1. Добавьте тип эффекта в `ItemEffectType`
В [lib/models/item_card.dart](file:///i:/dev/card_dungeon/lib/models/item_card.dart):
```dart
enum ItemEffectType {
  heal,
  attack,
  // ...
  freezeTime, // <-- Новый тип эффекта
}
```

### Шаг 2. Добавьте текстовое название и бейдж в `ItemEffectTypeExtension`
В том же файле [lib/models/item_card.dart](file:///i:/dev/card_dungeon/lib/models/item_card.dart):
```dart
extension ItemEffectTypeExtension on ItemEffectType {
  String get categoryLabel => switch (this) {
    // ...
    ItemEffectType.freezeTime => 'Контроль',
  };

  String getBadge(int value) => switch (this) {
    // ...
    ItemEffectType.freezeTime => '❄️ Заморозка',
  };
}
```

### Шаг 3. Объявите предмет в `allItemCards`
В [lib/data/items.dart](file:///i:/dev/card_dungeon/lib/data/items.dart):
```dart
ItemCard(
  id: 'hourglass_freeze',
  title: 'Песочные часы времени',
  description: 'Замораживает противника, нейтрализуя любой входящий урон на 2 хода.',
  effectType: ItemEffectType.freezeTime,
  value: 2,
  icon: Icons.hourglass_bottom_rounded,
  color: Color(0xFF00BCD4),
),
```

### Шаг 4. Реализуйте игровую механику в `GameScreen._useItem`
В [lib/screens/game_screen.dart](file:///i:/dev/card_dungeon/lib/screens/game_screen.dart) внутри метода `_useItem`:
```dart
case ItemEffectType.freezeTime:
  // Ваша логика: например, добавить заряды или флаг
  _lastFeedback = 'Время заморожено на ${item.value} хода!';
  _addJournalEntry('❄️', 'Использовано ${item.title}: заморозка');
  resultTitle = 'Заморозка времени ❄️';
  resultDescription = 'Вы активировали артефакт: следующие ${item.value} встречи пройдут без вреда для героя.';
  break;
```

---

## 7. Настройка прокачки и баланса

Все параметры постоянной прокачки персонажа настраиваются в [lib/services/player_stats_service.dart](file:///i:/dev/card_dungeon/lib/services/player_stats_service.dart):

| Параметр | Константа в коде | Значение по умолчанию | Формула стоимости |
| :--- | :--- | :--- | :--- |
| **Базовое здоровье** | `baseHealth` | `10 HP` | — |
| **Прирост HP за уровень** | `healthPerLevel` | `+2 HP` | `25 + level * 25` (25, 50, 75...) |
| **Макс. уровень HP** | `maxHealthLevel` | `10` (макс. 30 HP) | — |
| **Базовая атака** | `baseAttack` | `5 ⚡` | — |
| **Прирост атаки за ур.** | `attackPerLevel` | `+1 ⚡` | `30 + level * 30` (30, 60, 90...) |
| **Макс. уровень атаки** | `maxAttackLevel` | `10` (макс. 15 ⚡) | — |
| **Торговцы** | `maxMerchantLevel` | `2` торговца | `60 + level * 40` (60, 100) |
| **Стартовые карты** | `maxStartingCardsLevel` | `3` карты | `50 + level * 50` (50, 100, 150) |

### Настройка цен в магазине:
В [lib/screens/shop_screen.dart](file:///i:/dev/card_dungeon/lib/screens/shop_screen.dart):
- `_baseLootboxPrice = 50`: начальная цена первого лутбокса;
- `_lootboxPriceStep = 25`: шаг роста цены за каждый уже открытый артефакт.

---

## 8. Инструменты тестирования и отладки

Для удобного тестирования механик в игре предусмотрен встроенный **Экран отладки** (`DebugScreen`), доступный по иконке шестерёнки в правом верхнем углу Главного меню:
- **Баланс монет**: мгновенное начисление или списание любой суммы золота.
- **Коллекция карт**: кнопки «Открыть все карты» и «Сбросить все карты».
- **Глоссарий**: открытие всех событий для проверки бестиария.
- **Характеристики**: ползунки и кнопки быстрой настройки уровней здоровья, атаки и навыков.
- **Тестовый забег**: кнопка запуска игры сразу с заданного этажа или с полным инвентарём.

### Запуск автоматических тестов:
```bash
flutter test
```

### Статический анализ:
```bash
dart analyze
```
