import 'package:flutter/material.dart';

import '../../../core/design_system/chamfered_border.dart';
import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_layout.dart';
import '../models/skill.dart';

/// عقدة مهارة واحدة. تُعزل داخل RepaintBoundary حتى لا تتسبب إعادة رسمها
/// في إعادة رسم بقية الشجرة، وهذا مهم جداً للأداء.
class SkillNodeWidget extends StatelessWidget {
  const SkillNodeWidget({
    super.key,
    required this.skill,
    required this.onTap,
    required this.onLongPress,
  });

  final Skill skill;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = _NodePalette.fromStatus(skill.status);

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: SkillTreeLayout.nodeBoxWidth,
          height: SkillTreeLayout.nodeBoxHeight,
          child: Column(
            children: [
              SizedBox(
                width: SkillTreeLayout.nodeDiameter,
                height: SkillTreeLayout.nodeDiameter,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      width: SkillTreeLayout.nodeDiameter,
                      height: SkillTreeLayout.nodeDiameter,
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: palette.gradient,
                        ),
                        shape: ChamferedBorder(
                          cut: 17,
                          dashed: skill.status == SkillStatus.locked,
                          glow: skill.status == SkillStatus.available,
                          side: BorderSide(
                            color: palette.border,
                            width:
                                skill.status == SkillStatus.unlocked ? 2.5 : 2,
                          ),
                        ),
                      ),
                      child: Icon(
                        skill.icon,
                        size: 30,
                        color: palette.icon,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: AppColors.background,
                          border: Border.all(
                            color: palette.border.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Icon(
                          skill.type == SkillType.active
                              ? Icons.bolt
                              : Icons.shield,
                          size: 11,
                          color: palette.icon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                skill.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: skill.status == SkillStatus.unlocked
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: palette.text,
                ),
              ),
              if (skill.status != SkillStatus.unlocked) ...[
                const SizedBox(height: 2),
                Text(
                  '${skill.cost} SP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: palette.cost,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NodePalette {
  const _NodePalette({
    required this.gradient,
    required this.border,
    required this.icon,
    required this.text,
    required this.cost,
  });

  final List<Color> gradient;
  final Color border;
  final Color icon;
  final Color text;
  final Color cost;

  factory _NodePalette.fromStatus(SkillStatus status) {
    switch (status) {
      case SkillStatus.locked:
        return const _NodePalette(
          gradient: [Color(0xFF151B20), Color(0xFF0D1115)],
          border: Color(0xFF56616B),
          icon: Color(0xFF77838D),
          text: AppColors.textSub,
          cost: AppColors.inactive,
        );
      case SkillStatus.available:
        return _NodePalette(
          gradient: [
            AppColors.surface,
            AppColors.primary.withValues(alpha: 0.28),
          ],
          border: AppColors.primary,
          icon: AppColors.accent,
          text: AppColors.textMain,
          cost: AppColors.accent,
        );
      case SkillStatus.unlocked:
        return _NodePalette(
          gradient: [
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.65),
          ],
          border: AppColors.accent,
          icon: Colors.white,
          text: Colors.white,
          cost: AppColors.accent,
        );
    }
  }
}
