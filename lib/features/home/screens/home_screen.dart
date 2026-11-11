import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/chamfered_border.dart';
import '../../../core/design_system/system_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../../tasks/tasks_screen.dart';
import '../../skills/skills_screen.dart';
import '../../body/body_screen.dart';
import '../../profile/profile_screen.dart';
import '../../ranks/ranks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('SHADOWDEV // STATUS'),
              actions: [
                IconButton(
                  onPressed: _openProfile,
                  icon: const Icon(
                    PhosphorIconsRegular.userCircle,
                    color: AppColors.primary,
                    size: 34,
                  ),
                  tooltip: 'الملف الشخصي',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(),
                  const TasksScreen(),
                  const SkillsScreen(),
                  const RanksScreen(),
                  const BodyScreen(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return SystemPanel(
      padding: const EdgeInsets.all(5),
      active: true,
      child: Row(
        children: [
          _buildNavItem(
            0,
            PhosphorIconsRegular.house,
            PhosphorIconsFill.house,
            'الحالة',
          ),
          _buildNavItem(
            1,
            PhosphorIconsRegular.listChecks,
            PhosphorIconsFill.listChecks,
            'المهام',
          ),
          _buildNavItem(
            2,
            PhosphorIconsRegular.star,
            PhosphorIconsFill.star,
            'المهارات',
          ),
          _buildNavItem(
            3,
            PhosphorIconsRegular.medal,
            PhosphorIconsFill.medal,
            'الرتب',
          ),
          _buildNavItem(
            4,
            PhosphorIconsRegular.barbell,
            PhosphorIconsFill.barbell,
            'الجسد',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_currentIndex == index) return;
          setState(() => _currentIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: ShapeDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: ChamferedBorder(
              cut: 7,
              side: BorderSide(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? AppColors.accent : AppColors.textSub,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.textMain : AppColors.textSub,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final Widget content;

        if (player.isLoading) {
          content = const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        } else if (player.errorMessage != null) {
          content = Center(
            key: const ValueKey('error'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsRegular.cloudSlash,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    player.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: player.fetchPlayerData,
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          content = _buildHomeContent(player);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: content,
        );
      },
    );
  }

  Widget _buildHomeContent(PlayerProvider player) {
    return SingleChildScrollView(
      key: const ValueKey('content'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayerCard(player),
          const SizedBox(height: 12),
          _buildStreakCard(player),
          const SizedBox(height: 12),
          _buildStatusRadarCard(player),
          const SizedBox(height: 12),
          _buildTasksCard(player),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerProvider player) {
    final xpIntoLevel =
        player.xpToNextLevel > 0 ? player.xp % player.xpToNextLevel : 0;
    final progress = player.xpToNextLevel > 0
        ? xpIntoLevel / player.xpToNextLevel
        : 0.0;
    return SystemPanel(
      active: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SystemTag('PLAYER PROFILE', compact: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: ShapeDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: const ChamferedBorder(
                    cut: 12,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAYER // LVL ${player.level}',
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.xp} XP TOTAL',
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              SystemTag('${player.rank}-RANK'),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEXT LEVEL',
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$xpIntoLevel / ${player.xpToNextLevel} XP',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.surfaceRaised,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(PlayerProvider player) {
    final hasStreak = player.currentStreak > 0;

    return SystemPanel(
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.fire,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak
                      ? '${player.currentStreak} أيام متتالية'
                      : 'ابدأ سلسلتك اليوم',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'حافظ على سلسلتك اليومية',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRadarCard(PlayerProvider player) {
    final stats = player.stats;
    final values = <num>[
      stats['mind'] ?? 0,
      stats['body'] ?? 0,
      stats['work'] ?? 0,
      stats['self_development'] ?? 0,
      stats['relations'] ?? 0,
    ];

    final maxValue = values.fold<int>(
      0,
      (current, value) => math.max(current, value.toInt()),
    );
    final maxTick = math.max(10, ((maxValue + 9) ~/ 10) * 10);
    final ticks = <int>[
      math.max(1, maxTick ~/ 4),
      math.max(2, maxTick ~/ 2),
      math.max(3, (maxTick * 3) ~/ 4),
      maxTick,
    ];

    final xpIntoLevel =
        player.xpToNextLevel > 0 ? player.xp % player.xpToNextLevel : 0;
    final progress = player.xpToNextLevel > 0
        ? xpIntoLevel / player.xpToNextLevel
        : 0.0;

    return SystemPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.crosshair,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'نافذة الحالة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '[${player.rank}-RANK]',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'المستوى ${player.level} • ${player.xp} XP',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 290,
            child: RadarChart(
              ticks: ticks,
              features: const ['عقل', 'جسد', 'عمل', 'نفس', 'علاقات'],
              data: [values],
              featuresTextStyle: const TextStyle(
                color: AppColors.textMain,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              ticksTextStyle: const TextStyle(
                color: AppColors.textSub,
                fontSize: 9,
              ),
              outlineColor: AppColors.primary.withValues(alpha: 0.5),
              axisColor: Colors.white.withValues(alpha: 0.12),
              graphColors: const [AppColors.accent],
              sides: 5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSub,
                ),
              ),
              Text(
                '$xpIntoLevel / ${player.xpToNextLevel}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(PlayerProvider player) {
    final remaining =
        player.tasksTotal > player.tasksCompleted
            ? player.tasksTotal - player.tasksCompleted
            : 0;
    return SystemPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.checkCircle,
                color: AppColors.accent,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مهامك اليومية بانتظارك',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remaining > 0
                          ? '$remaining من ${player.tasksTotal} مهام متبقية اليوم'
                          : 'أكملت كل مهام اليوم، أحسنت!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SystemButton(
            label: 'ابدأ الآن',
            icon: Icons.arrow_forward,
            onPressed: _openTasksTab,
          ),
        ],
      ),
    );
  }

  void _openTasksTab() {
    setState(() => _currentIndex = 1);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}
