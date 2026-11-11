import 'package:flutter_test/flutter_test.dart';
import 'package:shadowdev/features/skills/models/skill.dart';

void main() {
  test('parses a backend skill and its unlock state', () {
    final skill = Skill.fromJson(const {
      'skill_id': 7,
      'skill_key': 'discipline',
      'name': 'الانضباط الأساسي',
      'stage': 1,
      'description': 'أساس كل تقدم.',
      'icon_name': 'shield',
      'skill_type': 'passive',
      'cost': 1,
      'x': 700,
      'y': 1560,
      'prerequisites': <String>[],
      'status': 'beginner',
      'is_unlocked': true,
    });

    expect(skill.backendId, 7);
    expect(skill.id, 'discipline');
    expect(skill.title, 'الانضباط الأساسي');
    expect(skill.status, SkillStatus.unlocked);
    expect(skill.type, SkillType.passive);
  });

  test('rejects an incomplete backend skill', () {
    expect(
      () => Skill.fromJson(const {'skill_id': 7, 'skill_key': 'discipline'}),
      throwsFormatException,
    );
  });
}
