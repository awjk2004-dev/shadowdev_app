import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/skill.dart';

enum UnlockResult { success, locked, notEnoughPoints, alreadyUnlocked }

class SkillTreeProvider extends ChangeNotifier {
  SkillTreeProvider({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final List<Skill> _skills = <Skill>[];
  final Set<String> _unlockedIds = <String>{};
  int _skillPoints = 0;
  bool isLoading = false;
  bool isMutating = false;
  String? errorMessage;

  List<Skill> get skills => List<Skill>.unmodifiable(_skills);

  int get skillPoints => _skillPoints;

  int get unlockedCount => _unlockedIds.length;

  Future<void> fetchSkills() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        _apiClient.getSkills(),
        _apiClient.getPlayerData(),
      ]);
      final rawSkills = responses[0].data;
      final playerData = responses[1].data;
      if (rawSkills is! List || playerData is! Map) {
        throw const FormatException('Invalid skill tree response');
      }

      final skills = rawSkills.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid skill entry from backend');
        }
        return Skill.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false);
      final ids = skills.map((skill) => skill.id).toSet();
      final backendIds = skills.map((skill) => skill.backendId).toSet();
      if (ids.length != skills.length ||
          backendIds.length != skills.length ||
          backendIds.contains(null)) {
        throw const FormatException('Duplicate or missing skill identifiers');
      }

      final rawPoints = playerData['skill_points'];
      if (rawPoints is! num || rawPoints < 0) {
        throw const FormatException('Skill point balance is missing');
      }

      _skills
        ..clear()
        ..addAll(skills);
      _unlockedIds
        ..clear()
        ..addAll(
          skills
              .where((skill) => skill.status == SkillStatus.unlocked)
              .map((skill) => skill.id),
        );
      _skillPoints = rawPoints.toInt();
      _recomputeStatuses();
    } catch (error, stackTrace) {
      errorMessage = 'تعذر تحميل شجرة المهارات. تحقق من الاتصال وحاول مجددًا.';
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'skill tree loading',
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
  Future<UnlockResult> unlock(String id) async {
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
    final backendId = skill.backendId;
    if (backendId == null) {
      throw StateError('Skill is missing its backend identifier');
    }

    isMutating = true;
    notifyListeners();
    try {
      final response = await _apiClient.unlockSkill(backendId);
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Invalid skill unlock response');
      }
      final unlockedSkill = Skill.fromJson(Map<String, dynamic>.from(data));
      final rawPoints = data['skill_points'];
      if (unlockedSkill.id != id ||
          unlockedSkill.status != SkillStatus.unlocked ||
          rawPoints is! num ||
          rawPoints < 0) {
        throw const FormatException('Invalid skill unlock response');
      }

      _skillPoints = rawPoints.toInt();
      _unlockedIds.add(id);
      _skills[index] = unlockedSkill;
      _recomputeStatuses();
      return UnlockResult.success;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    isMutating = true;
    notifyListeners();
    try {
      final response = await _apiClient.resetSkillTree();
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Invalid skill reset response');
      }
      final rawPoints = data['skill_points'];
      if (rawPoints is! num || rawPoints < 0) {
        throw const FormatException('Invalid skill reset response');
      }

      _skillPoints = rawPoints.toInt();
      _unlockedIds.clear();
      _recomputeStatuses();
    } finally {
      isMutating = false;
      notifyListeners();
    }
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
