import '../models/event_card.dart';

// ═══════════════════════════════════════════════
//  Обычные события (уровни 1 и 2)
// ═══════════════════════════════════════════════

const List<EventCard> allEvents = [
  // ── УРОВЕНЬ 1 ────────────────────────────────
  EventCard(
    id: 'goblin',
    type: EventType.monster,
    title: 'Гоблин-разбойник',
    description:
        'Из тени выскакивает вооружённый гоблин и требует плату за проход.',
    leftChoice: CardChoice(label: 'Сражаться', attackDelta: -2),
    rightChoice: CardChoice(
      label: 'Отдать золото',
      healthDelta: -1,
      attackDelta: 1,
      coinsDelta: -5,
    ),
    level: 1,
  ),
  EventCard(
    id: 'spikes',
    type: EventType.trap,
    title: 'Шипастая ловушка',
    description:
        'Пол под ногами скрипит подозрительно. Кажется, здесь спрятана ловушка.',
    leftChoice: CardChoice(label: 'Осторожно обойти'),
    rightChoice: CardChoice(
      label: 'Прыгнуть через',
      healthDelta: -2,
      attackDelta: 1,
    ),
    level: 1,
  ),
  EventCard(
    id: 'chest',
    type: EventType.treasure,
    title: 'Сундук с сокровищами',
    description: 'Перед вами старый сундук, покрытый пылью веков.',
    leftChoice: CardChoice(label: 'Открыть', coinsDelta: 15),
    rightChoice: CardChoice(label: 'Игнорировать'),
    level: 1,
  ),
  EventCard(
    id: 'skeleton',
    type: EventType.monster,
    title: 'Скелет-страж',
    description: 'Живой мертвец блокирует коридор, поднимая ржавый меч.',
    leftChoice: CardChoice(
      label: 'Атаковать',
      healthDelta: -1,
      attackDelta: -2,
    ),
    rightChoice: CardChoice(label: 'Отступить', healthDelta: 1),
    level: 1,
  ),
  EventCard(
    id: 'fountain',
    type: EventType.rest,
    title: 'Магический источник',
    description: 'В тёмном зале бьёт источник с мягким голубым светом.',
    leftChoice: CardChoice(label: 'Выпить воды', healthDelta: 3),
    rightChoice: CardChoice(label: 'Наполнить флягу', attackDelta: 3),
    level: 1,
  ),
  EventCard(
    id: 'item_merchant',
    type: EventType.merchant,
    title: 'Торговец реликвиями',
    description:
        'Таинственный торговец открывает сумку с магическими зельями и свитками.',
    leftChoice: CardChoice(
      label: 'Купить предмет',
      coinsDelta: -10,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(label: 'Идти дальше'),
    level: 1,
  ),
  EventCard(
    id: 'merchant',
    type: EventType.merchant,
    title: 'Странствующий торговец',
    description: 'Торговец предлагает зелье силы или амулет исцеления.',
    leftChoice: CardChoice(
      label: 'Купить зелье',
      healthDelta: 2,
      coinsDelta: -8,
    ),
    rightChoice: CardChoice(label: 'Идти дальше'),
    level: 1,
  ),
  EventCard(
    id: 'pit',
    type: EventType.trap,
    title: 'Пропасть',
    description: 'Коридор обрывается в глубокую бездну. Как перебраться?',
    leftChoice: CardChoice(label: 'Перепрыгнуть', healthDelta: -2),
    rightChoice: CardChoice(label: 'Обойти', healthDelta: 1),
    level: 1,
  ),
  EventCard(
    id: 'dark_altar',
    type: EventType.mystery,
    title: 'Тёмный алтарь',
    description: 'Алтарь пульсирует тёмной энергией. Что-то шепчет вам.',
    leftChoice: CardChoice(
      label: 'Прикоснуться',
      healthDelta: -3,
      attackDelta: 3,
    ),
    rightChoice: CardChoice(
      label: 'Разрушить',
      healthDelta: 1,
      attackDelta: -1,
    ),
    level: 1,
  ),
  EventCard(
    id: 'wolf',
    type: EventType.monster,
    title: 'Голодный волк',
    description: 'Из-за колонны выходит худая, но злая тварь.',
    leftChoice: CardChoice(label: 'Бросить еду', healthDelta: -2),
    rightChoice: CardChoice(label: 'Сразиться', attackDelta: -2),
    level: 1,
  ),
  EventCard(
    id: 'gold_pile',
    type: EventType.treasure,
    title: 'Куча золота',
    description:
        'На полу лежит блестящая куча монет. Слишком хорошо, чтобы быть правдой?',
    leftChoice: CardChoice(label: 'Собрать', healthDelta: -3, coinsDelta: 30),
    rightChoice: CardChoice(
      label: 'Не трогать',
      healthDelta: 1,
      attackDelta: 1,
    ),
    level: 1,
  ),
  EventCard(
    id: 'campfire',
    type: EventType.rest,
    title: 'Заброшенный костёр',
    description: 'Кто-то недавно был здесь. Угли ещё тёплые.',
    leftChoice: CardChoice(label: 'Отдохнуть', healthDelta: 2),
    rightChoice: CardChoice(
      label: 'Разжечь костёр',
      healthDelta: 1,
      attackDelta: 1,
    ),
    level: 1,
  ),
  EventCard(
    id: 'poison_dart',
    type: EventType.trap,
    title: 'Отравленные стрелы',
    description: 'Из стены вылетает залп стрел!',
    leftChoice: CardChoice(label: 'Укрыться', healthDelta: -1),
    rightChoice: CardChoice(label: 'Блокировать щитом', attackDelta: -2),
    level: 1,
  ),
  EventCard(
    id: 'ghost',
    type: EventType.mystery,
    title: 'Призрак стража',
    description: 'Полупрозрачная фигура просит помочь найти покой.',
    leftChoice: CardChoice(label: 'Помочь', healthDelta: -2, attackDelta: 2),
    rightChoice: CardChoice(label: 'Изгнать', healthDelta: -3, attackDelta: 3),
    level: 1,
  ),
  EventCard(
    id: 'armory',
    type: EventType.treasure,
    title: 'Заброшенная оружейная',
    description: 'На стенах висят старые, но крепкие клинки.',
    leftChoice: CardChoice(
      label: 'Взять меч',
      attackDelta: 2,
      healthDelta: -1,
      coinsDelta: 10,
    ),
    rightChoice: CardChoice(
      label: 'Взять броню',
      healthDelta: 2,
      attackDelta: -1,
      coinsDelta: 10,
    ),
    level: 1,
  ),
  EventCard(
    id: 'slime',
    type: EventType.monster,
    title: 'Кислотная слизь',
    description: 'Липкая масса блокирует проход и шипит.',
    leftChoice: CardChoice(label: 'Сжечь', healthDelta: -3, attackDelta: 1),
    rightChoice: CardChoice(label: 'Обойти', healthDelta: -2),
    level: 1,
  ),
  EventCard(
    id: 'cursed_shrine',
    type: EventType.mystery,
    title: 'Проклятое святилище',
    description: 'Статуя смотрит на вас пустыми глазницами. Воздух густеет.',
    leftChoice: CardChoice(label: 'Молиться', healthDelta: -1, attackDelta: 2),
    rightChoice: CardChoice(label: 'Пройти мимо', healthDelta: -2),
    level: 1,
  ),
  EventCard(
    id: 'bandits',
    type: EventType.monster,
    title: 'Засада разбойников',
    description: 'Трое бандитов перекрывают узкий проход.',
    leftChoice: CardChoice(
      label: 'Прорваться',
      healthDelta: -4,
      attackDelta: 1,
    ),
    rightChoice: CardChoice(
      label: 'Договориться',
      healthDelta: -3,
      attackDelta: -1,
    ),
    level: 1,
  ),
  EventCard(
    id: 'healing_herbs',
    type: EventType.rest,
    title: 'Редкие травы',
    description: 'У стены растут светящиеся растения с приятным ароматом.',
    leftChoice: CardChoice(label: 'Съесть', healthDelta: 2),
    rightChoice: CardChoice(label: 'Сохранить', healthDelta: 1, attackDelta: 1),
    level: 1,
  ),

  // ── УРОВЕНЬ 2 ────────────────────────────────
  EventCard(
    id: 'troll',
    type: EventType.monster,
    title: 'Пещерный тролль',
    description:
        'Огромная туша перегораживает проход, сотрясая пол при каждом шаге.',
    leftChoice: CardChoice(
      label: 'Атаковать в лоб',
      healthDelta: -5,
      attackDelta: 2,
      coinsDelta: 20,
    ),
    rightChoice: CardChoice(
      label: 'Заманить в ловушку',
      healthDelta: -3,
      attackDelta: -1,
      coinsDelta: 10,
    ),
    level: 2,
  ),
  EventCard(
    id: 'lava_crack',
    type: EventType.trap,
    title: 'Лавовые трещины',
    description: 'Пол покрыт трещинами, из которых пробиваются языки пламени.',
    leftChoice: CardChoice(
      label: 'Перебежать быстро',
      healthDelta: -4,
      attackDelta: 1,
    ),
    rightChoice: CardChoice(
      label: 'Искать обход',
      healthDelta: -1,
      coinsDelta: -10,
    ),
    level: 2,
  ),
  EventCard(
    id: 'dragon_hoard',
    type: EventType.treasure,
    title: 'Сокровищница дракона',
    description:
        'Горы золота в спящем логове дракона. Но хозяин может проснуться.',
    leftChoice: CardChoice(label: 'Взять всё', healthDelta: -5, coinsDelta: 60),
    rightChoice: CardChoice(label: 'Взять немного', coinsDelta: 25),
    level: 2,
  ),
  EventCard(
    id: 'black_market',
    type: EventType.merchant,
    title: 'Чёрный рынок',
    description:
        'Подозрительный торговец предлагает редкие и мощные артефакты.',
    leftChoice: CardChoice(
      label: 'Купить артефакт',
      coinsDelta: -20,
      givesRandomItem: true,
    ),
    rightChoice: CardChoice(
      label: 'Грабить торговца',
      healthDelta: -3,
      attackDelta: 3,
      coinsDelta: 15,
    ),
    level: 2,
  ),
  EventCard(
    id: 'cursed_well',
    type: EventType.rest,
    title: 'Проклятый колодец',
    description:
        'Вода светится зловещим светом. Может исцелить, а может и навредить.',
    leftChoice: CardChoice(label: 'Выпить', healthDelta: 5, attackDelta: -2),
    rightChoice: CardChoice(label: 'Умыться', healthDelta: 2, coinsDelta: 5),
    level: 2,
  ),
  EventCard(
    id: 'ancient_golem',
    type: EventType.monster,
    title: 'Древний голем',
    description: 'Каменный страж пробуждается от тысячелетнего сна.',
    leftChoice: CardChoice(
      label: 'Уничтожить ядро',
      healthDelta: -4,
      attackDelta: -2,
      coinsDelta: 30,
    ),
    rightChoice: CardChoice(
      label: 'Обезвредить',
      healthDelta: -6,
      attackDelta: 3,
    ),
    level: 2,
  ),
  EventCard(
    id: 'necromancer',
    type: EventType.mystery,
    title: 'Некромант',
    description:
        'Тёмный маг предлагает сделку — жизненную силу в обмен на знание.',
    leftChoice: CardChoice(
      label: 'Принять силу',
      healthDelta: -4,
      attackDelta: 4,
    ),
    rightChoice: CardChoice(
      label: 'Сжечь свитки',
      healthDelta: -2,
      coinsDelta: 25,
    ),
    level: 2,
  ),
  EventCard(
    id: 'fire_rune',
    type: EventType.trap,
    title: 'Огненные руны',
    description:
        'Пол усеян древними рунами. Одно неверное движение — и вспыхнет всё.',
    leftChoice: CardChoice(
      label: 'Разгадать узор',
      healthDelta: -1,
      attackDelta: 2,
    ),
    rightChoice: CardChoice(
      label: 'Рвануть через них',
      healthDelta: -5,
      coinsDelta: 15,
    ),
    level: 2,
  ),
  EventCard(
    id: 'vampiric_bat',
    type: EventType.monster,
    title: 'Стая вампирских летучих мышей',
    description: 'Из темноты вырывается рой кровопийц. Они везде!',
    leftChoice: CardChoice(
      label: 'Отбиться факелом',
      healthDelta: -3,
      attackDelta: 1,
    ),
    rightChoice: CardChoice(label: 'Укрыться', healthDelta: -4, coinsDelta: 10),
    level: 2,
  ),
  EventCard(
    id: 'soul_forge',
    type: EventType.mystery,
    title: 'Горнило душ',
    description: 'Артефакт поглощает жизненную силу и обращает её в мощь.',
    leftChoice: CardChoice(
      label: 'Влить всё здоровье',
      healthDelta: -5,
      attackDelta: 5,
    ),
    rightChoice: CardChoice(
      label: 'Частичная жертва',
      healthDelta: -2,
      attackDelta: 2,
      coinsDelta: 10,
    ),
    level: 2,
  ),
];

// ═══════════════════════════════════════════════
//  Карточки боссов (циклически на каждом 20-м ходу)
// ═══════════════════════════════════════════════

const List<EventCard> allBossCards = [
  EventCard(
    id: 'boss_guardian',
    type: EventType.boss,
    title: 'Страж Первого Этажа',
    description:
        'Массивный каменный колосс встаёт на пути. Его глаза пылают красным огнём, а удары сотрясают своды подземелья.',
    leftChoice: CardChoice(
      label: 'Атаковать',
      healthDelta: -5,
      attackDelta: 2,
      coinsDelta: 25,
    ),
    rightChoice: CardChoice(
      label: 'Обойти',
      healthDelta: -2,
      attackDelta: -2,
      coinsDelta: -15,
    ),
    level: 1,
  ),
  EventCard(
    id: 'boss_undead_knight',
    type: EventType.boss,
    title: 'Проклятый Рыцарь',
    description:
        'Некогда великий воин, теперь прикованный к этим чертогам проклятием. Его чёрный клинок не знает пощады.',
    leftChoice: CardChoice(
      label: 'Принять бой',
      healthDelta: -6,
      attackDelta: 3,
      coinsDelta: 35,
    ),
    rightChoice: CardChoice(
      label: 'Снять проклятие',
      healthDelta: -3,
      attackDelta: -3,
      coinsDelta: -20,
    ),
    level: 2,
  ),
  EventCard(
    id: 'boss_archfiend',
    type: EventType.boss,
    title: 'Архидемон Бездны',
    description:
        'Из разлома между мирами выходит существо из чистой тьмы. Реальность вокруг него трещит и распадается.',
    leftChoice: CardChoice(
      label: 'Сразиться',
      healthDelta: -8,
      attackDelta: 4,
      coinsDelta: 50,
    ),
    rightChoice: CardChoice(
      label: 'Заключить пакт',
      healthDelta: -4,
      attackDelta: -4,
      coinsDelta: -25,
    ),
    level: 3,
  ),
];
