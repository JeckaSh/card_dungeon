import 'package:flutter_test/flutter_test.dart';
import 'package:kki_cardgame/data/events.dart';
import 'package:kki_cardgame/models/event_card.dart';

void main() {
  group('Баланс карт событий (allEvents и allBossCards)', () {
    final allCards = [...allEvents, ...allBossCards];

    for (final card in allCards) {
      test('Карта [${card.id}] "${card.title}" соответствует правилам баланса', () {
        final left = card.leftChoice;
        final right = card.rightChoice;

        final leftAffectsHealth = left.healthDelta != 0;
        final leftAffectsAttack = left.attackDelta != 0;
        final rightAffectsHealth = right.healthDelta != 0;
        final rightAffectsAttack = right.attackDelta != 0;

        // 1. Ни один выбор не должен влиять и на здоровье, и на атаку одновременно
        expect(
          leftAffectsHealth && leftAffectsAttack,
          isFalse,
          reason: 'Левый выбор карты ${card.id} не должен влиять одновременно на HP и ATK',
        );
        expect(
          rightAffectsHealth && rightAffectsAttack,
          isFalse,
          reason: 'Правый выбор карты ${card.id} не должен влиять одновременно на HP и ATK',
        );

        // 2. Каждый выбор должен влиять либо на здоровье, либо на атаку
        expect(
          leftAffectsHealth || leftAffectsAttack,
          isTrue,
          reason: 'Левый выбор карты ${card.id} должен влиять либо на здоровье, либо на атаку',
        );
        expect(
          rightAffectsHealth || rightAffectsAttack,
          isTrue,
          reason: 'Правый выбор карты ${card.id} должен влиять либо на здоровье, либо на атаку',
        );

        // 3. Варианты выбора не должны влиять на одну и ту же характеристику
        expect(
          leftAffectsHealth == rightAffectsHealth,
          isFalse,
          reason: 'Оба выбора карты ${card.id} влияют на одну и ту же характеристику (Здоровье)',
        );
        expect(
          leftAffectsAttack == rightAffectsAttack,
          isFalse,
          reason: 'Оба выбора карты ${card.id} влияют на одну и ту же характеристику (Атака)',
        );

        // 4. Проверка на устранение тупиковых ситуаций (deadlock):
        // При 0 атаки и 0 монет хотя бы один выбор должен быть доступен (не заблокирован)
        final leftBlockedAtZero = (left.attackDelta < 0) || (left.coinsDelta < 0) || left.givesRandomItem;
        final rightBlockedAtZero = (right.attackDelta < 0) || (right.coinsDelta < 0) || right.givesRandomItem;

        expect(
          leftBlockedAtZero && rightBlockedAtZero,
          isFalse,
          reason: 'Карта ${card.id} вызывает тупик (оба выбора заблокированы при 0 атаки / 0 монет)',
        );

        // 5. Монеты должны давать только сокровища (и в редких случаях боссы/торговцы/тайны)
        // Обычные монстры, ловушки и отдых не должны влиять на монеты.
        if (card.type == EventType.monster ||
            card.type == EventType.trap ||
            card.type == EventType.rest) {
          expect(
            left.coinsDelta,
            equals(0),
            reason: 'Обычная карта ${card.type.name} (${card.id}) не должна давать/отнимать монеты в левом выборе',
          );
          expect(
            right.coinsDelta,
            equals(0),
            reason: 'Обычная карта ${card.type.name} (${card.id}) не должна давать/отнимать монеты в правом выборе',
          );
        }
      });
    }

    test('Боссы представляют реальную опасность (требуют ресурсы и наносят урон)', () {
      for (final boss in allBossCards) {
        final left = boss.leftChoice;
        final right = boss.rightChoice;

        // Один выбор требует атаку, второй наносит ощутимый урон здоровью
        final hasAttackCost = left.attackDelta < 0 || right.attackDelta < 0;
        final hasHealthCost = left.healthDelta < 0 || right.healthDelta < 0;

        expect(hasAttackCost, isTrue, reason: 'Босс ${boss.id} должен требовать атаку');
        expect(hasHealthCost, isTrue, reason: 'Босс ${boss.id} должен наносить урон здоровью');
      }
    });
  });
}
