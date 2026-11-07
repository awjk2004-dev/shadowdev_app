import 'package:flutter/foundation.dart';

import '../data/default_skill_tree.dart';
import '../models/skill.dart';

enum UnlockResult { success, locked, notEnoughPoints, alreadyUnlocked }

/// يدير حالة شجرة المهارات بالكامل: النقاط، الحالات، والمتطلبات.
///
/// كل شيء محلي (in-memory) وسريع، ويمكن ربطه لاحقاً بالباك اند عبر
/// استدعاء [addSkill] / [addSkills] أو بإضافة طبقة مزامنة خارجية.
class SkillTreeProvider extends ChangeNotifier {
  SkillTreeProvider({
    List<Skill>? skills,
    int initialSkillPoints = 10,
  })  : _skills = List<Skill>.of(skills ?? defaultSkillTree),
        _skillPoints = initialSkillPoints {
    _recomputeStatuses();
  }

  final List<Skill> _skills;
  final Set<String> _unlockedIds = <String>{};
  int _skillPoints;

  List<Skill> get skills => List<Skill>.unmodifiable(_skills);

  int get skillPoints => _skillPoints;

  int get unlockedCount => _unlockedIds.length;

  Skill? byId(String id) {
    for (final skill in _skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }

  bool isAffordable(Skill skill) => _skillPoints >= skill.cost;

  List<Skill> missingPrerequisites(Skill skill) {
    return skill.prerequisites
        .where((id) => !_unlockedIds.contains(id))
        .map(byId)
        .whereType<Skill>()
        .toList(growable: false);
  }

  /// يحاول فتح مهارة. يعيد النتيجة حتى تعرض الواجهة رسالة مناسبة.
  UnlockResult unlock(String id) {
    final index = _skills.indexWhere((skill) => skill.id == id);
    if (index == -1) return UnlockResult.locked;

    final skill = _skills[index];
    if (skill.status == SkillStatus.unlocked) {
      return UnlockResult.alreadyUnlocked;
    }
    if (skill.status == SkillStatus.locked) {
      return UnlockResult.locked;
    }
    if (_skillPoints < skill.cost) {
      return UnlockResult.notEnoughPoints;
    }

    _skillPoints -= skill.cost;
    _unlockedIds.add(id);
    _recomputeStatuses();
    notifyListeners();
    return UnlockResult.success;
  }

  /// إضافة مهارة مخصصة واحدة (Dynamic Addition).
  void addSkill(Skill skill) {
    if (_skills.any((existing) => existing.id == skill.id)) return;
    _skills.add(skill);
    _recomputeStatuses();
    notifyListeners();
  }

  /// إضافة عدة مهارات دفعة واحدة.
  void addSkills(Iterable<Skill> skills) {
    var changed = false;
    for (final skill in skills) {
      if (_skills.any((existing) => existing.id == skill.id)) continue;
      _skills.add(skill);
      changed = true;
    }
    if (!changed) return;
    _recomputeStatuses();
    notifyListeners();
  }

  /// إعادة تعيين الشجرة مع الاحتفاظ بالمهارات المضافة.
  void reset({int skillPoints = 10}) {
    _unlockedIds.clear();
    _skillPoints = skillPoints;
    _recomputeStatuses();
    notifyListeners();
  }

  void _recomputeStatuses() {
    for (var i = 0; i < _skills.length; i++) {
      final skill = _skills[i];
      final SkillStatus status;
      if (_unlockedIds.contains(skill.id)) {
        status = SkillStatus.unlocked;
      } else if (skill.prerequisites.every(_unlockedIds.contains)) {
        status = SkillStatus.available;
      } else {
        status = SkillStatus.locked;
      }
      if (status != skill.status) {
        _skills[i] = skill.copyWith(status: status);
      }
    }
  }
}
