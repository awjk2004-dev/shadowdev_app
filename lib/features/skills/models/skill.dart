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
      prerequisites: prerequisites ?? this.prerequisites,
      status: status ?? this.status,
      icon: icon ?? this.icon,
    );
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
