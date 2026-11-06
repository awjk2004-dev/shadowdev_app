import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/player_provider.dart';
import '../../tasks/tasks_screen.dart';
import '../../skills/skills_screen.dart';
import '../../body/body_screen.dart';
import '../../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider()..fetchPlayerData(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _currentIndex == 0
            ? AppBar(
                title: const Text(
                  'مرحباً بك',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.surface.withValues(alpha: 0.85),
                      AppColors.background,
                    ],
                    radius: 1.5,
                  ),
                ),
                child: SafeArea(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildHomeTab(),
                      const TasksScreen(),
                      const SkillsScreen(),
                      const BodyScreen(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildFloatingNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                0,
                PhosphorIconsRegular.house,
                PhosphorIconsFill.house,
                'الرئيسية',
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
                PhosphorIconsRegular.barbell,
                PhosphorIconsFill.barbell,
                'الجسد',
              ),
            ],
          ),
        ),
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  )
                : null,
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
          _buildStreakCard(player),
          const SizedBox(height: 16),
          _buildStatusRadarCard(player),
          const SizedBox(height: 16),
          _buildTasksCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStreakCard(PlayerProvider player) {
    final hasStreak = player.currentStreak > 0;

    return _GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              PhosphorIconsRegular.fire,
              color: AppColors.primary,
              size: 32,
            ),
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

    final progress = (player.xp % 100) / 100;

    return _GlassCard(
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
                  '${player.rank}-RANK',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                '${player.xp % 100} / 100',
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

  Widget _buildTasksCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                PhosphorIconsRegular.checkCircle,
                color: AppColors.accent,
                size: 26,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لديك 3 مهام متبقية اليوم',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _openTasksTab,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'ابدأ الآن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
