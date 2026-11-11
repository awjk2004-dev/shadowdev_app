import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/chamfered_border.dart';
import '../../core/theme/app_theme.dart';
import 'data/skill_tree_layout.dart';
import 'models/skill.dart';
import 'providers/skill_tree_provider.dart';
import 'widgets/skill_node.dart';
import 'widgets/skill_tree_painter.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

String _actionErrorMessage(Object error) {
  if (error is DioException && error.response?.data is Map) {
    final detail = error.response!.data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
  }
  return 'تعذر حفظ التغيير على الخادم. حاول مرة أخرى.';
}

class _SkillsScreenState extends State<SkillsScreen>
    with AutomaticKeepAliveClientMixin {
  final TransformationController _transformController =
      TransformationController();

  Size _viewport = Size.zero;
  bool _viewInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<SkillTreeProvider>().fetchSkills());
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SKILL TREE // شجرة المهارات'),
        actions: [
          Consumer<SkillTreeProvider>(
            builder: (context, tree, _) {
              return Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: ShapeDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: ChamferedBorder(
                      cut: 7,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Text(
                    '[SP ${tree.skillPoints}]',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer<SkillTreeProvider>(
            builder: (context, tree, _) {
              return IconButton(
                tooltip: 'إعادة تعيين الشجرة',
                onPressed:
                    tree.skills.isEmpty || tree.isLoading || tree.isMutating
                        ? null
                        : _confirmReset,
                icon: const Icon(Icons.restart_alt),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<SkillTreeProvider>(
        builder: (context, tree, _) {
          if (tree.isLoading && tree.skills.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tree.errorMessage != null && tree.skills.isEmpty) {
            return _buildLoadError(context, tree);
          }
          if (tree.skills.isEmpty) {
            return _buildNoSkills(tree);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              _viewport = Size(constraints.maxWidth, constraints.maxHeight);
              if (!_viewInitialized) {
                _viewInitialized = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _centerTree(_viewport);
                });
              }

              return Stack(
                children: [
                  Positioned.fill(child: _buildTree(context, tree)),
                  _buildLegend(),
                  _buildZoomControls(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoSkills(SkillTreeProvider tree) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لا توجد مهارات مرتبطة بهذا الحساب. تأكد من تطبيق تحديثات الباك إند.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  tree.isLoading ? null : () => unawaited(tree.fetchSkills()),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(BuildContext context, SkillTreeProvider tree) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tree.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  tree.isLoading ? null : () => unawaited(tree.fetchSkills()),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTree(BuildContext context, SkillTreeProvider tree) {
    final skills = tree.skills;

    return InteractiveViewer(
      transformationController: _transformController,
      constrained: false,
      minScale: SkillTreeLayout.minScale,
      maxScale: SkillTreeLayout.maxScale,
      boundaryMargin: const EdgeInsets.all(300),
      child: SizedBox(
        width: SkillTreeLayout.canvasWidth,
        height: SkillTreeLayout.canvasHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: SkillTreePainter(skills: skills),
                ),
              ),
            ),
            for (final skill in skills)
              Positioned(
                key: ValueKey(skill.id),
                left: skill.x - SkillTreeLayout.nodeBoxWidth / 2,
                top: skill.y - SkillTreeLayout.nodeDiameter / 2,
                child: SkillNodeWidget(
                  skill: skill,
                  onTap: () => _showSkillDetails(context, tree, skill),
                  onLongPress: () => _showSkillDetails(context, tree, skill),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSkillTap(
    BuildContext context,
    SkillTreeProvider tree,
    Skill skill,
  ) async {
    final UnlockResult result;
    try {
      result = await tree.unlock(skill.id);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'skill unlock',
        ),
      );
      if (context.mounted) {
        _showMessage(
          context,
          _actionErrorMessage(error),
          AppColors.surface,
        );
      }
      return;
    }

    if (!context.mounted) return;

    switch (result) {
      case UnlockResult.success:
        _showMessage(
          context,
          'تم فتح «${skill.title}» — تبقّى ${tree.skillPoints} SP',
          AppColors.primary,
        );
        break;
      case UnlockResult.notEnoughPoints:
        final missing = skill.cost - tree.skillPoints;
        _showMessage(
          context,
          'تحتاج $missing SP إضافية لفتح «${skill.title}»',
          AppColors.surface,
        );
        break;
      case UnlockResult.locked:
        final missing = tree
            .missingPrerequisites(skill)
            .map((item) => item.title)
            .join('، ');
        _showMessage(
          context,
          missing.isEmpty
              ? '«${skill.title}» مقفلة حالياً'
              : '«${skill.title}» تتطلب: $missing',
          AppColors.surface,
        );
        break;
      case UnlockResult.alreadyUnlocked:
        _showSkillDetails(context, tree, skill);
        break;
    }
  }

  void _showMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _showSkillDetails(
    BuildContext context,
    SkillTreeProvider tree,
    Skill skill,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final missing = tree.missingPrerequisites(skill);
        final canUnlock = skill.status == SkillStatus.available &&
            tree.skillPoints >= skill.cost &&
            !tree.isMutating;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: ShapeDecoration(
            color: AppColors.surface,
            shape: ChamferedBorder(
              cut: 18,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Icon(skill.icon, color: AppColors.accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${skill.type.label} • ${skill.status.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${skill.cost} SP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  skill.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSub,
                  ),
                ),
                if (skill.prerequisites.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'المتطلبات',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in skill.prerequisites)
                        _RequirementChip(
                          title: tree.byId(id)?.title ?? id,
                          met: !missing.any((item) => item.id == id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: skill.status == SkillStatus.unlocked
                        ? null
                        : canUnlock
                            ? () {
                                Navigator.of(sheetContext).pop();
                                unawaited(_onSkillTap(context, tree, skill));
                              }
                            : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.06),
                      disabledForegroundColor: AppColors.textSub,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const ChamferedBorder(cut: 10),
                    ),
                    icon: Icon(
                      skill.status == SkillStatus.unlocked
                          ? Icons.check_circle
                          : skill.status == SkillStatus.locked
                              ? Icons.lock
                              : Icons.lock_open,
                    ),
                    label: Text(
                      skill.status == SkillStatus.unlocked
                          ? 'مفتوحة'
                          : skill.status == SkillStatus.locked
                              ? 'أكمل المتطلبات أولاً'
                              : canUnlock
                                  ? 'فتح المهارة (-${skill.cost} SP)'
                                  : 'نقاط SP غير كافية',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReset() {
    final tree = context.read<SkillTreeProvider>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const ChamferedBorder(
            cut: 14,
            side: BorderSide(color: AppColors.primary),
          ),
          title: const Text(
            'إعادة التعيين',
            style: TextStyle(color: AppColors.textMain),
          ),
          content: const Text(
            'سيتم إغلاق المهارات المفتوحة واستعادة نقاط SP المكتسبة. هل تريد المتابعة؟',
            style: TextStyle(color: AppColors.textSub),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: tree.isMutating
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      try {
                        await tree.reset();
                        if (mounted) {
                          _showMessage(
                            context,
                            'تمت إعادة تعيين شجرة المهارات',
                            AppColors.primary,
                          );
                        }
                      } catch (error, stackTrace) {
                        FlutterError.reportError(
                          FlutterErrorDetails(
                            exception: error,
                            stack: stackTrace,
                            library: 'skill tree reset',
                          ),
                        );
                        if (mounted) {
                          _showMessage(
                            context,
                            _actionErrorMessage(error),
                            AppColors.surface,
                          );
                        }
                      }
                    },
              child: const Text('إعادة'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 12,
      left: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendDot(color: Color(0x66FFFFFF), label: 'مقفلة'),
              SizedBox(width: 10),
              _LegendDot(color: AppColors.primary, label: 'متاحة'),
              SizedBox(width: 10),
              _LegendDot(color: AppColors.accent, label: 'مفتوحة'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 110,
      child: Column(
        children: [
          _ZoomButton(
            icon: Icons.add,
            tooltip: 'تكبير',
            onPressed: () => _zoomBy(1.25),
          ),
          const SizedBox(height: 8),
          _ZoomButton(
            icon: Icons.remove,
            tooltip: 'تصغير',
            onPressed: () => _zoomBy(0.8),
          ),
          const SizedBox(height: 8),
          _ZoomButton(
            icon: Icons.center_focus_strong,
            tooltip: 'توسيط',
            onPressed: () => _centerTree(_viewport),
          ),
        ],
      ),
    );
  }

  void _zoomBy(double factor) {
    if (_viewport == Size.zero) return;

    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor)
        .clamp(SkillTreeLayout.minScale, SkillTreeLayout.maxScale);
    if ((targetScale - currentScale).abs() < 0.001) return;

    final viewportCenter = Offset(_viewport.width / 2, _viewport.height / 2);
    final sceneCenter = _transformController.toScene(viewportCenter);

    _transformController.value = Matrix4.identity()
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale)
      ..setEntry(0, 3, viewportCenter.dx - sceneCenter.dx * targetScale)
      ..setEntry(1, 3, viewportCenter.dy - sceneCenter.dy * targetScale);
  }

  void _centerTree(Size viewport) {
    if (viewport == Size.zero) return;

    const scale = SkillTreeLayout.initialScale;
    final skills = context.read<SkillTreeProvider>().skills;

    const focusX = SkillTreeLayout.canvasWidth / 2;
    var focusY = SkillTreeLayout.canvasHeight / 2;
    if (skills.isNotEmpty) {
      var maxY = skills.first.y;
      for (final skill in skills) {
        if (skill.y > maxY) maxY = skill.y;
      }
      // نركّز على منطقة الجذر (أسفل الشجرة) حيث تبدأ المهارات المتاحة.
      focusY = (maxY - 150).clamp(0.0, SkillTreeLayout.canvasHeight);
    }

    final dx = viewport.width / 2 - focusX * scale;
    final dy = viewport.height / 2 - focusY * scale;

    _transformController.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSub),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: AppColors.accent),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.title, required this.met});

  final String title;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.accent : AppColors.textSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
