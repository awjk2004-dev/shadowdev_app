import 'package:flutter/material.dart';

import '../../../core/design_system/chamfered_border.dart';
import '../../../core/theme/app_theme.dart';
import '../models/skill.dart';

/// يرسم خطوط الربط بين كل مهارة ومتطلباتها.
///
/// لا ظلال ولا تأثيرات ثقيلة: خطوط بسيطة فقط، مع repaint ذكي حتى لا يعيد
/// الرسم إلا عند تغيّر حالة أي مهارة.
class SkillTreePainter extends CustomPainter {
  SkillTreePainter({required this.skills});

  final List<Skill> skills;

  @override
  void paint(Canvas canvas, Size size) {
    if (skills.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const gridSize = 48.0;
    for (var x = 0.0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final byId = <String, Skill>{
      for (final skill in skills) skill.id: skill,
    };

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final child in skills) {
      if (child.prerequisites.isEmpty) continue;
      for (final parentId in child.prerequisites) {
        final parent = byId[parentId];
        if (parent == null) continue;

        paint
          ..strokeWidth = child.status == SkillStatus.unlocked ? 3.0 : 2.0
          ..color = _lineColor(parent, child);

        final path = Path()
          ..moveTo(parent.x, parent.y)
          ..lineTo(child.x, child.y);
        if (child.status == SkillStatus.locked) {
          drawDashedPath(canvas, path, paint, dash: 8, gap: 7);
        } else {
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  Color _lineColor(Skill parent, Skill child) {
    if (child.status == SkillStatus.unlocked) {
      return AppColors.accent.withValues(alpha: 0.85);
    }
    if (child.status == SkillStatus.available) {
      return AppColors.primary.withValues(alpha: 0.7);
    }
    return AppColors.inactive.withValues(alpha: 0.4);
  }

  @override
  bool shouldRepaint(covariant SkillTreePainter oldDelegate) {
    return _signature(oldDelegate.skills) != _signature(skills);
  }

  String _signature(List<Skill> list) {
    return list.map((skill) => '${skill.id}:${skill.status.name}').join('|');
  }
}
