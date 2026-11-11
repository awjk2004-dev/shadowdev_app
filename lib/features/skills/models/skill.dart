import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// نوع المهارة: نشطة أو سلبية.
enum SkillType { active, passive }

/// حالة المهارة على الشجرة.
enum SkillStatus { locked, available, unlocked }

extension SkillTypeLabel on SkillType {
  String get label => switch (this) {
        SkillType.active => 'نشطة',
        SkillType.passive => 'سلبية',
      };
}

extension SkillStatusLabel on SkillStatus {
  String get label => switch (this) {
        SkillStatus.locked => 'مقفلة',
        SkillStatus.available => 'متاحة',
        SkillStatus.unlocked => 'مفتوحة',
      };
}

/// عقدة مهارة واحدة على الشجرة.
///
/// الإحداثيات [x] و [y] تمثل مركز دائرة المهارة داخل لوحة الرسم
/// (وليس الزاوية العلوية اليسرى).
@immutable
class Skill {
  const Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.cost,
    required this.x,
    required this.y,
    this.backendId,
    this.prerequisites = const <String>[],
    this.status = SkillStatus.locked,
    this.icon = Icons.auto_awesome,
  });

  final String id;
  final String title;
  final String description;
  final SkillType type;
  final int cost;
  final double x;
  final double y;
  final int? backendId;
  final List<String> prerequisites;
  final SkillStatus status;
  final IconData icon;

  bool get isRoot => prerequisites.isEmpty;

  Skill copyWith({
    String? title,
    String? description,
    SkillType? type,
    SkillStatus? status,
    int? cost,
    double? x,
    double? y,
    int? backendId,
    List<String>? prerequisites,
    IconData? icon,
  }) {
    return Skill(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      cost: cost ?? this.cost,
      x: x ?? this.x,
      y: y ?? this.y,
      backendId: backendId ?? this.backendId,
      prerequisites: prerequisites ?? this.prerequisites,
      status: status ?? this.status,
      icon: icon ?? this.icon,
    );
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    final id = json['skill_key'];
    final backendId = json['skill_id'];
    final type = json['skill_type'];
    final prerequisites = json['prerequisites'];
    final isUnlocked = json['is_unlocked'];
    final x = json['x'];
    final y = json['y'];
    final cost = json['cost'];

    if (id is! String ||
        id.isEmpty ||
        backendId is! num ||
        type is! String ||
        prerequisites is! List ||
        prerequisites.any((value) => value is! String) ||
        isUnlocked is! bool ||
        x is! num ||
        y is! num ||
        cost is! num ||
        json['name'] is! String ||
        json['description'] is! String) {
      throw const FormatException('Invalid skill data from backend');
    }

    final skillType = switch (type) {
      'active' => SkillType.active,
      'passive' => SkillType.passive,
      _ => throw FormatException('Unknown skill type: $type'),
    };

    return Skill(
      id: id,
      backendId: backendId.toInt(),
      title: json['name'] as String,
      description: json['description'] as String,
      type: skillType,
      cost: cost.toInt(),
      x: x.toDouble(),
      y: y.toDouble(),
      prerequisites: prerequisites.cast<String>(),
      status: isUnlocked ? SkillStatus.unlocked : SkillStatus.locked,
      icon: _iconFor(json['icon_name']),
    );
  }

  static IconData _iconFor(Object? name) {
    return switch (name) {
      'shield' => Icons.shield,
      'center_focus_strong' => Icons.center_focus_strong,
      'visibility' => Icons.visibility,
      'favorite' => Icons.favorite,
      'psychology' => Icons.psychology,
      'castle' => Icons.castle,
      'balance' => Icons.balance,
      'air' => Icons.air,
      'bolt' => Icons.bolt,
      'security' => Icons.security,
      'dark_mode' => Icons.dark_mode,
      'blur_on' => Icons.blur_on,
      'sports_martial_arts' => Icons.sports_martial_arts,
      'auto_awesome' => Icons.auto_awesome,
      'workspace_premium' => Icons.workspace_premium,
      _ => Icons.auto_awesome,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Skill &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.cost == cost &&
        other.x == x &&
        other.y == y &&
        other.status == status &&
        listEquals(other.prerequisites, prerequisites);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        type,
        cost,
        x,
        y,
        status,
        Object.hashAll(prerequisites),
      );
}
