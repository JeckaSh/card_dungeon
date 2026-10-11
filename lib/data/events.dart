import '../models/event_card.dart';

// ═══════════════════════════════════════════════════════════════
//  КАРТЫ СОБЫТИЙ (ОБЩИЕ КАРТЫ + ПРОКЛЯТЫЙ ЛЕС)
//  Прежний набор перенесён в legacy_events.dart
// ═══════════════════════════════════════════════════════════════

/// Реестр всех стандартных карт событий в игре (за исключением боссов).
///
/// Каждая карта содержит:
/// * [level] — номер этажа (1, 2, 3...), на котором она встречается;
/// * [dungeonId] — принадлежность к подземелью ([DungeonId.cursedForest] или общий пул [DungeonId.common]);
/// * [leftChoice] и [rightChoice] — два варианта выбора для игрока со своими эффектами.
///
/// Баланс карт:
/// В соответствии с игровым балансом каждый выбор влияет либо строго на здоровье
/// (и в редких случаях сокровищ на монеты), либо строго на атаку (и в редких случаях сокровищ на монеты).
/// Два выбора на одной карте не влияют на одну и ту же характеристику, исключая тупиковые ситуации.
/// Большинство карт подземелья (монстры, ловушки, отдых) не дают монет: монеты генерируются сундуками/сокровищами.
///
/// Для добавления нового события:
/// 1. Создайте `EventCard` в соответствующей секции уровня;
/// 2. Укажите уникальный `id` (используется для сохранения открытых карт в глоссарии);
/// 3. Назначьте `type`, заголовки и последствия выборов.
const List<EventCard> allEvents = [
  // ─────────────────────────────────────────────────────────────
  //  УРОВЕНЬ 1: Опушка и Сумрачная Чаща
  // ─────────────────────────────────────────────────────────────

  // ── Общие карты (сокровища и торговцы) ──
  EventCard(
    id: 'chest',
    type: EventType.treasure,
    title: 'Сундук с сокровищами',
    description: 'Перед вами старый сундук, покрытый пылью веков.',
    leftChoice: CardChoice(
      label: 'Открыть осторожно',
      healthDelta: 1,
      coinsDelta: 15,
    ),
    rightChoice: CardChoice(
      label: 'Сбить замок силой',
      attackDelta: 1,
      coinsDelta: 10,
    ),
    level: 1,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'item_merchant',
    type: EventType.merchant,
    title: 'Торговец реликвиями',
    description:
        'Таинственный торговец открывает сумку с магическими зельями и свитками.',
    leftChoice: CardChoice(
      label: 'Купить реликвию силы',
      attackDelta: 1,
      coinsDelta: -10,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Передохнуть у лавки',
      healthDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'merchant',
    type: EventType.merchant,
    title: 'Странствующий торговец',
    description: 'Торговец предлагает целебные отвары или уроки фехтования.',
    leftChoice: CardChoice(
      label: 'Купить зелье здоровья',
      healthDelta: 3,
      coinsDelta: -8,
    ),
    rightChoice: CardChoice(
      label: 'Тренировка с чучелом',
      attackDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'mimic',
    type: EventType.treasure,
    title: 'Подозрительный сундук',
    description: 'Сундук выглядит богато, но ручка слегка подрагивает.',
    leftChoice: CardChoice(
      label: 'Осторожно вскрыть замок',
      healthDelta: -3,
      coinsDelta: 20,
    ),
    rightChoice: CardChoice(
      label: 'Разрубить мимика ударом',
      attackDelta: -1,
      coinsDelta: 10,
    ),
    level: 1,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'vault',
    type: EventType.treasure,
    title: 'Запечатанная сокровищница',
    description: 'Каменная плита скрывает нишу с золотом. Нужна грубая сила.',
    leftChoice: CardChoice(
      label: 'Сдвинуть плиту силой',
      attackDelta: -2,
      coinsDelta: 25,
    ),
    rightChoice: CardChoice(
      label: 'Протиснуться сквозь щель',
      healthDelta: -2,
      coinsDelta: 12,
    ),
    level: 1,
    dungeonId: DungeonId.common,
  ),

  // ── Тематические карты: Проклятый лес (Уровень 1) ──
  EventCard(
    id: 'forest_wolf_lone',
    type: EventType.monster,
    title: 'Одичавший лютоволк',
    description:
        'Из сумрачных зарослей тихо выступает крупный пепельный волк с голодным оскалом.',
    leftChoice: CardChoice(
      label: 'Сразить клинком',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Отбиться телом',
      healthDelta: -3,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_viper_nest',
    type: EventType.trap,
    title: 'Змеиный выводок',
    description:
        'Под ногой хрустит мох, и из сухих ветвей взвивается ядовитая болотная гадюка. Опасность эффекта: Отравление (35%).',
    leftChoice: CardChoice(
      label: 'Отсечь голову на лету',
      attackDelta: -1,
    ),
    rightChoice: CardChoice(
      label: 'Раздавить сапогом',
      healthDelta: -2,
      statusEffect: StatusEffectType.poison,
      statusChance: 0.35,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_poacher_snare',
    type: EventType.trap,
    title: 'Капкан зверолова',
    description:
        'Скрытый под опавшей листвой ржавый стальной капкан с зубьями щелкает в шаге от вас. Опасность эффекта: Кровотечение (35%).',
    leftChoice: CardChoice(
      label: 'Перерубить трос мечом',
      attackDelta: -1,
    ),
    rightChoice: CardChoice(
      label: 'Вырвать ногу из капкана',
      healthDelta: -2,
      statusEffect: StatusEffectType.bleed,
      statusChance: 0.35,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_wild_boar',
    type: EventType.monster,
    title: 'Клыкастый вепрь',
    description:
        'Свирепый лесной кабан, покрытый шрамами и засохшей глиной, с ревом несётся напролом.',
    leftChoice: CardChoice(
      label: 'Встретить копьем на скаку',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Принять таран на щит',
      healthDelta: -3,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_healing_spring',
    type: EventType.rest,
    title: 'Родник дриады',
    description:
        'Журчащий лесной ключ омывает замшелые камни. Вода отдаёт свежестью и ароматом хвои.',
    leftChoice: CardChoice(
      label: 'Напиться целебной воды',
      healthDelta: 3,
    ),
    rightChoice: CardChoice(
      label: 'Омыть и заточить клинок',
      attackDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_whispering_bramble',
    type: EventType.trap,
    title: 'Шепчущий терновник',
    description:
        'Колючие плети терновника шевелятся сами по себе, перегораживая тропу живой изгородью.',
    leftChoice: CardChoice(
      label: 'Прорубить терновник',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Протиснуться сквозь шипы',
      healthDelta: -2,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_witch_mushrooms',
    type: EventType.mystery,
    title: 'Ведьмина поляна',
    description:
        'Круг из фосфоресцирующих грибов манит тусклым изумрудным сиянием в полумраке. Опасность эффекта: Слепота (30%).',
    leftChoice: CardChoice(
      label: 'Съесть светящийся гриб',
      healthDelta: -1,
      statusEffect: StatusEffectType.blindness,
      statusChance: 0.3,
    ),
    rightChoice: CardChoice(
      label: 'Растоптать грибной круг',
      attackDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_raven_flock',
    type: EventType.monster,
    title: 'Воронья стая',
    description:
        'Черные вороны с кроваво-красными клювами пикируют с крон, ослепляя хлопаньем крыльев. Опасность эффекта: Слепота (35%).',
    leftChoice: CardChoice(
      label: 'Разогнать факелом',
      attackDelta: -1,
    ),
    rightChoice: CardChoice(
      label: 'Прикрыться плащом',
      healthDelta: -2,
      statusEffect: StatusEffectType.blindness,
      statusChance: 0.35,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_hollow_oak',
    type: EventType.mystery,
    title: 'Дуплистый дуб',
    description:
        'В глубине дупла векового дуба что-то поблескивает среди сухих ветвей и паутины.',
    leftChoice: CardChoice(
      label: 'Запустить руку в дупло',
      healthDelta: -2,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Осмотреть дупло клинком',
      attackDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_peat_bog',
    type: EventType.trap,
    title: 'Торфяная трясина',
    description:
        'Кажущаяся твёрдой тропа внезапно проседает — холодная топь засасывает по колено.',
    leftChoice: CardChoice(
      label: 'Опереться на шест и выпрыгнуть',
      attackDelta: -1,
    ),
    rightChoice: CardChoice(
      label: 'Выбраться через трясину',
      healthDelta: -2,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_herbalist_hut',
    type: EventType.rest,
    title: 'Хижина травницы',
    description:
        'Среди зарослей папоротника стоит покосившаяся хижина со связками сушёных целебных трав.',
    leftChoice: CardChoice(
      label: 'Целебный настой травницы',
      healthDelta: 2,
    ),
    rightChoice: CardChoice(
      label: 'Помочь расколоть брёвна',
      attackDelta: 1,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_night_stalker',
    type: EventType.monster,
    title: 'Лесная рысь',
    description:
        'Хищная пятнистая кошка с кисточками на ушах бесшумно спрыгивает с ветви за спиной.',
    leftChoice: CardChoice(
      label: 'Опережающий выпад клинка',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Принять прыжок на доспех',
      healthDelta: -3,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),

  // ─────────────────────────────────────────────────────────────
  //  УРОВЕНЬ 2: Гнилое Урочище и Мглистые Топи
  // ─────────────────────────────────────────────────────────────

  // ── Общие карты (сокровища и торговцы) ──
  EventCard(
    id: 'cursed_chest',
    type: EventType.treasure,
    title: 'Проклятый сундук',
    description:
        'Сундук с черными рунами манит золотом, но от него веет могильным холодом.',
    leftChoice: CardChoice(
      label: 'Вскрыть и забрать',
      healthDelta: -5,
      coinsDelta: 40,
    ),
    rightChoice: CardChoice(
      label: 'Разрубить оковы силой',
      attackDelta: -2,
      coinsDelta: 30,
    ),
    level: 2,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'black_market',
    type: EventType.merchant,
    title: 'Подпольный скупщик',
    description:
        'Фигура в плаще с капюшоном торгует мощным оружием по сходной цене.',
    leftChoice: CardChoice(
      label: 'Купить заточенный клинок',
      attackDelta: 3,
      coinsDelta: -15,
    ),
    rightChoice: CardChoice(
      label: 'Передохнуть у костра скупщика',
      healthDelta: 2,
    ),
    level: 2,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'dungeon_smuggler',
    type: EventType.merchant,
    title: 'Контрабандист подземелья',
    description:
        'Ловкий делец готов продать ценный предмет тому, у кого есть золото.',
    leftChoice: CardChoice(
      label: 'Купить редкое снаряжение',
      attackDelta: 2,
      coinsDelta: -18,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Выпить целебного вина',
      healthDelta: 3,
    ),
    level: 2,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'cursed_idol_greed',
    type: EventType.treasure,
    title: 'Идол алчности',
    description:
        'Золотая статуэтка с рубиновыми глазами шепчет об обещании несметных богатств. Опасность эффекта: Проклятие Мидаса (40%).',
    leftChoice: CardChoice(
      label: 'Сорвать рубины силой',
      attackDelta: -1,
      coinsDelta: 35,
      statusEffect: StatusEffectType.midasCurse,
      statusChance: 0.4,
    ),
    rightChoice: CardChoice(
      label: 'Поклониться и исцелиться',
      healthDelta: 3,
    ),
    level: 2,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'secret_vault',
    type: EventType.treasure,
    title: 'Потайная кладовая',
    description:
        'Скрытая за ложной стеной кладовая полна забытых монет и драгоценностей.',
    leftChoice: CardChoice(
      label: 'Взломать решётку силой',
      attackDelta: -2,
      coinsDelta: 35,
    ),
    rightChoice: CardChoice(
      label: 'Пролезть сквозь узкую щель',
      healthDelta: -3,
      coinsDelta: 20,
    ),
    level: 2,
    dungeonId: DungeonId.common,
  ),

  // ── Тематические карты: Проклятый лес (Уровень 2) ──
  EventCard(
    id: 'forest_bear_slumber',
    type: EventType.monster,
    title: 'Медведь-шатун',
    description:
        'Огромный бурый медведь, поражённый скверной леса, с бешеным рёвом крушит стволы деревьев.',
    leftChoice: CardChoice(
      label: 'Сразить зверя мечом',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Принять удар когтей',
      healthDelta: -5,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_marsh_kikimora',
    type: EventType.monster,
    title: 'Болотная кикимора',
    description:
        'Горбатая тварь в тине и лохмотьях с шипением плюется едкой желчью из гнилого омута. Опасность эффекта: Отравление (40%).',
    leftChoice: CardChoice(
      label: 'Рассечь нечисть клинком',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Прорваться сквозь желчь',
      healthDelta: -4,
      statusEffect: StatusEffectType.poison,
      statusChance: 0.4,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_blighted_treant',
    type: EventType.monster,
    title: 'Осквернённый дендроид',
    description:
        'Живое дерево с растрескавшейся чёрной корой и горящими гнилушками преграждает путь.',
    leftChoice: CardChoice(
      label: 'Срубить чёрный ствол',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Проломить ветви телом',
      healthDelta: -5,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_giant_spider',
    type: EventType.monster,
    title: 'Ловчий паук-древолаз',
    description:
        'Восьмилапый монстр размером с лошадь спускается на клейкой нити, щёлкая ядовитыми жвалами. Опасность эффекта: Отравление (35%).',
    leftChoice: CardChoice(
      label: 'Пронзить ядовитое брюхо',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Разорвать паутину телом',
      healthDelta: -4,
      statusEffect: StatusEffectType.poison,
      statusChance: 0.35,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_hunting_pit',
    type: EventType.trap,
    title: 'Охотничья яма с кольями',
    description:
        'Маскировка из веток осыпается, обнажая дно глубокой волчьей ямы с заострёнными кольями. Опасность эффекта: Кровотечение (40%).',
    leftChoice: CardChoice(
      label: 'Зацепиться за край клинком',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Спрыгнуть на острые уступы',
      healthDelta: -4,
      statusEffect: StatusEffectType.bleed,
      statusChance: 0.4,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_sacred_totem',
    type: EventType.mystery,
    title: 'Идол Лесного Рогача',
    description:
        'Грубо вырезанный из морёного дуба тотем увенчан ветвистыми рогами. От него веет древней силой. Опасность эффекта: Проклятие Мидаса (35%).',
    leftChoice: CardChoice(
      label: 'Пожертвовать монеты за силу',
      attackDelta: 2,
      coinsDelta: -10,
    ),
    rightChoice: CardChoice(
      label: 'Сорвать амулеты жертвы',
      healthDelta: -3,
      coinsDelta: 20,
      statusEffect: StatusEffectType.midasCurse,
      statusChance: 0.35,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_ranger_camp',
    type: EventType.rest,
    title: 'Лагерь следопыта',
    description:
        'Заброшенная стоянка егеря: тлеющие угли в кострище и кожаные походные тюки.',
    leftChoice: CardChoice(
      label: 'Согреться у костра',
      healthDelta: 4,
    ),
    rightChoice: CardChoice(
      label: 'Заточить клинок бруском',
      attackDelta: 2,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_scorpion_stalker',
    type: EventType.monster,
    title: 'Шипастый скорпид',
    description:
        'Панцирный лесной хищник с ядовитым хвостом-кинжалом атакует из-под упавшего бревна. Опасность эффекта: Кровотечение (35%).',
    leftChoice: CardChoice(
      label: 'Разбить панцирь клинком',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Отсечь жало щитом',
      healthDelta: -4,
      statusEffect: StatusEffectType.bleed,
      statusChance: 0.35,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_fog_spores',
    type: EventType.trap,
    title: 'Споровый дурман',
    description:
        'Гигантские ядовитые грибы лопаются, выбрасывая в воздух облако багровых едких спор. Опасность эффекта: Слепота (40%).',
    leftChoice: CardChoice(
      label: 'Рассечь грибницу мечом',
      attackDelta: -2,
    ),
    rightChoice: CardChoice(
      label: 'Бежать сквозь едкие споры',
      healthDelta: -3,
      statusEffect: StatusEffectType.blindness,
      statusChance: 0.4,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_enchanted_brook',
    type: EventType.rest,
    title: 'Заколдованный ручей',
    description:
        'Прозрачные струи ручья текут вспять, отражая созвездия даже сквозь густые кроны деревьев.',
    leftChoice: CardChoice(
      label: 'Испивать волшебную воду',
      healthDelta: 4,
    ),
    rightChoice: CardChoice(
      label: 'Закалить клинок в потоке',
      attackDelta: 2,
      givesRandomItem: true,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_shadow_pack',
    type: EventType.monster,
    title: 'Стая ночных хищников',
    description:
        'Дюжина горящих глаз окружает вас в чаще. Хищники готовятся к одновременному броску.',
    leftChoice: CardChoice(
      label: 'Встать к дереву и разить',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Прорвать кольцо телом',
      healthDelta: -5,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),

  // ─────────────────────────────────────────────────────────────
  //  УРОВЕНЬ 3: Сердце Чащи и Древо Скверны
  // ─────────────────────────────────────────────────────────────

  // ── Общие карты (сокровища и торговцы) ──
  EventCard(
    id: 'dragon_ancient',
    type: EventType.treasure,
    title: 'Логово древнего дракона',
    description: 'Дракон спит в окружении несметных богатств. Его дыхание поднимает дым.',
    leftChoice: CardChoice(
      label: 'Ограбить тихо',
      healthDelta: -6,
      coinsDelta: 80,
    ),
    rightChoice: CardChoice(
      label: 'Сразить дракона в сердце',
      attackDelta: -5,
      coinsDelta: 120,
    ),
    level: 3,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'relic_vault',
    type: EventType.treasure,
    title: 'Хранилище реликвий',
    description: 'За массивными воротами скрыты реликвии давно павшей цивилизации.',
    leftChoice: CardChoice(
      label: 'Взять реликвии силы',
      attackDelta: 3,
      coinsDelta: 70,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Благословение святилища',
      healthDelta: 5,
    ),
    level: 3,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'dimensional_merchant',
    type: EventType.merchant,
    title: 'Торговец из другого измерения',
    description: 'Существо вне времени и пространства предлагает артефакты из других миров.',
    leftChoice: CardChoice(
      label: 'Купить оружие иных миров',
      attackDelta: 3,
      coinsDelta: -30,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Принять астральное исцеление',
      healthDelta: 4,
    ),
    level: 3,
    dungeonId: DungeonId.common,
  ),
  EventCard(
    id: 'astral_trader',
    type: EventType.merchant,
    title: 'Астральный меняла',
    description:
        'Древний дух в мерцающих одеждах готов поделиться силой за плату.',
    leftChoice: CardChoice(
      label: 'Купить звёздный клинок',
      attackDelta: 3,
      coinsDelta: -25,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Наполниться энергией космоса',
      healthDelta: 4,
    ),
    level: 3,
    dungeonId: DungeonId.common,
  ),

  // ── Тематические карты: Проклятый лес (Уровень 3) ──
  EventCard(
    id: 'forest_wendigo_stalker',
    type: EventType.monster,
    title: 'Рогатый вендиго',
    description:
        'Иссохший костяной исполин с оленьим черепом вместо головы издает леденящий душу вой.',
    leftChoice: CardChoice(
      label: 'Сокрушить исполина клинком',
      attackDelta: -4,
    ),
    rightChoice: CardChoice(
      label: 'Выдержать леденящий натиск',
      healthDelta: -7,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_spider_matriarch',
    type: EventType.monster,
    title: 'Паучья Матриарх',
    description:
        'Громадная праматерь логова с раздутым брюхом ползёт навстречу, капая смертоносным ядом. Опасность эффекта: Отравление (45%).',
    leftChoice: CardChoice(
      label: 'Пронзить жвалы клинком',
      attackDelta: -4,
    ),
    rightChoice: CardChoice(
      label: 'Выдержать ядовитый плевок',
      healthDelta: -8,
      statusEffect: StatusEffectType.poison,
      statusChance: 0.45,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_chupacabra_behemoth',
    type: EventType.monster,
    title: 'Клыкастый кошколак',
    description:
        'Чудовищный хищник с саблезубыми клыками и стальными когтями атакует быстрее молнии.',
    leftChoice: CardChoice(
      label: 'Пронзить хищника на скаку',
      attackDelta: -4,
    ),
    rightChoice: CardChoice(
      label: 'Перекат под ударом когтей',
      healthDelta: -6,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_carnivorous_bloom',
    type: EventType.trap,
    title: 'Плотоядная росянка',
    description:
        'Растение размером с повозку с треском захлопывает шипастые лепестки, сочащиеся кислотой.',
    leftChoice: CardChoice(
      label: 'Разрубить стебель клинком',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Вырваться сквозь кислоту',
      healthDelta: -6,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_wisp_deadbog',
    type: EventType.trap,
    title: 'Блуждающие огни топей',
    description:
        'Призрачные огоньки заводят в трясину, где дно устлано костями былых охотников. Опасность эффекта: Слепота (45%).',
    leftChoice: CardChoice(
      label: 'Не поддаваться чарам',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Броситься в трясину',
      healthDelta: -5,
      statusEffect: StatusEffectType.blindness,
      statusChance: 0.45,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_black_gryphon',
    type: EventType.monster,
    title: 'Чернокрылый грифон',
    description:
        'Поражённый скверной полулев-полуорел пикирует с чёрных скал, рассекая воздух когтями.',
    leftChoice: CardChoice(
      label: 'Смертоносный выпад в сердце',
      attackDelta: -5,
    ),
    rightChoice: CardChoice(
      label: 'Принять пике на щит',
      healthDelta: -8,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_druid_circle',
    type: EventType.mystery,
    title: 'Круг падших друидов',
    description:
        'Окровавленные мегалиты пульсируют тёмной энергией. В центре лежит древняя реликвия леса. Опасность эффекта: Проклятие Мидаса (40%).',
    leftChoice: CardChoice(
      label: 'Впитать тёмную мощь',
      attackDelta: 3,
      statusEffect: StatusEffectType.midasCurse,
      statusChance: 0.4,
    ),
    rightChoice: CardChoice(
      label: 'Очистить древний алтарь',
      healthDelta: 5,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_bioluminescent_cave',
    type: EventType.rest,
    title: 'Грот светящегося мха',
    description:
        'Укромная пещера под корнями векового древа озарена мягким изумрудным исцеляющим сиянием.',
    leftChoice: CardChoice(
      label: 'Исцеляющий сон',
      healthDelta: 6,
    ),
    rightChoice: CardChoice(
      label: 'Медитация на силу',
      attackDelta: 3,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_root_rift',
    type: EventType.trap,
    title: 'Корневой разлом',
    description:
        'Исполинские корни шевелятся в глубине трещины земли, пытаясь утащить неосторожного путника.',
    leftChoice: CardChoice(
      label: 'Перерубить живые корни',
      attackDelta: -3,
    ),
    rightChoice: CardChoice(
      label: 'Карабкаться по трещине',
      healthDelta: -6,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_cursed_dryad',
    type: EventType.mystery,
    title: 'Проклятая дриада',
    description:
        'Плачущая лесная дева с ветвями вместо волос молит об избавлении от поглотившей её скверны.',
    leftChoice: CardChoice(
      label: 'Подарить целебный бальзам',
      healthDelta: -3,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Оборвать страдания клинком',
      attackDelta: 2,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
];

// ═══════════════════════════════════════════════════════════════
//  БОССЫ ПРОКЛЯТОГО ЛЕСА (появляются на каждом 20-м ходу)
// ═══════════════════════════════════════════════════════════════

/// Реестр карточек боссов подземелий.
///
/// Боссы появляются в конце каждого уровня (каждая 20-я карта забега).
/// У боссов:
/// * `type == EventType.boss`;
/// * [level] указывает номер этажа, на котором босс появляется;
/// * [dungeonId] привязывает босса к конкретному подземелью;
/// * Победа над боссом повышает этаж подземелья или приводит к финальной победе!
const List<EventCard> allBossCards = [
  EventCard(
    id: 'forest_boss_packleader',
    type: EventType.boss,
    title: 'Альфа-вожак Ночной Стаи',
    description:
        'Гигантский чёрный волк с пылающими янтарными глазами и зубами, способными перекусить латы. Его рёв созывает стаю со всех концов леса.',
    leftChoice: CardChoice(
      label: 'Выдержать яростный бросок',
      healthDelta: -6,
      coinsDelta: 25,
    ),
    rightChoice: CardChoice(
      label: 'Сразить вожака клинком',
      attackDelta: -3,
      coinsDelta: 30,
    ),
    level: 1,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_boss_swamp_hag',
    type: EventType.boss,
    title: 'Болотная Ведьма Моррига',
    description:
        'Древняя карга, вросшая в коряги мёртвого болота. Вокруг неё вьются ядовитые туманы, а костлявые руки сжимают чудовищный посох.',
    leftChoice: CardChoice(
      label: 'Прорваться сквозь скверну',
      healthDelta: -7,
      coinsDelta: 30,
    ),
    rightChoice: CardChoice(
      label: 'Разрубить колдовской посох',
      attackDelta: -4,
      coinsDelta: 40,
    ),
    level: 2,
    dungeonId: DungeonId.cursedForest,
  ),
  EventCard(
    id: 'forest_boss_ancient_leshy',
    type: EventType.boss,
    title: 'Древний Хозяин Леса',
    description:
        'Колосс из векового морёного дуба, переплетённых ветвей и оленьих рогов. Само сердце проклятого леса пульсирует в его груди!',
    leftChoice: CardChoice(
      label: 'Сразиться с владыкой леса',
      healthDelta: -8,
      coinsDelta: 40,
    ),
    rightChoice: CardChoice(
      label: 'Срубить древнее древо',
      attackDelta: -5,
      coinsDelta: 60,
    ),
    level: 3,
    dungeonId: DungeonId.cursedForest,
  ),
];
