import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String _currentRank = 'E';

  final List<Map<String, dynamic>> _ranks = const [
    {
      'rank': 'E',
      'title': 'البداية من الصفر',
      'req': 'المستوى 1+',
    },
    {
      'rank': 'D',
      'title': 'الوصول إلى المستوى 5',
      'req': 'المستوى 5+',
    },
    {
      'rank': 'C',
      'title': 'تبني أنظمة كاملة',
      'req': 'المستوى 10+',
    },
    {
      'rank': 'B',
      'title': 'تبني APIs',
      'req': 'المستوى 20+',
    },
    {
      'rank': 'A',
      'title': 'شغل حقيقي بعروض',
      'req': 'المستوى 35+',
    },
    {
      'rank': 'S',
      'title': 'محترف متوازن الحياة',
      'req': 'المستوى 50+',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchPlayerRank();
  }

  Future<void> _fetchPlayerRank() async {
    try {
      final response = await _apiClient.getPlayerData();
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _currentRank = response.data['rank']?.toString() ?? 'E';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سُلّم الرتب'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.surface.withValues(alpha: 0.85),
              AppColors.background,
            ],
            radius: 1.4,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  itemCount: _ranks.length,
                  itemBuilder: (context, index) {
                    final rankData = _ranks[index];
                    final rankOrder = ['E', 'D', 'C', 'B', 'A', 'S'];
                    final currentIndex = rankOrder.indexOf(_currentRank);
                    final thisIndex =
                        rankOrder.indexOf(rankData['rank'] as String);
                    final isCurrent = rankData['rank'] == _currentRank;
                    final isUnlocked = thisIndex <= currentIndex;

                    return Opacity(
                      opacity: isUnlocked ? 1.0 : 0.5,
                      child: _buildRankCard(
                        rankData: rankData,
                        isCurrent: isCurrent,
                        isUnlocked: isUnlocked,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRankCard({
    required Map<String, dynamic> rankData,
    required bool isCurrent,
    required bool isUnlocked,
  }) {
    final Color accentColor = isCurrent
        ? AppColors.accent
        : isUnlocked
            ? AppColors.primary
            : AppColors.textSub;

    final IconData statusIcon = isCurrent
        ? Icons.star
        : isUnlocked
            ? Icons.check_circle
            : Icons.lock;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.surface.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رتبة ${rankData['rank']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? AppColors.textMain
                              : isUnlocked
                                  ? AppColors.textMain
                                  : AppColors.textSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rankData['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCurrent
                              ? AppColors.textMain
                              : AppColors.textSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المتطلبات: ${rankData['req']}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primary
                          : accentColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      rankData['rank'] as String,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? AppColors.primary : accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
