import 'package:flutter/material.dart';

import '../../core/design_system/chamfered_border.dart';
import '../../core/design_system/system_widgets.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  String _currentRank = 'E';

  static const List<_Rank> _ranks = [
    _Rank('E', 'البداية من الصفر', 'المستوى 1+'),
    _Rank('D', 'بناء عادة ثابتة', 'المستوى 5+'),
    _Rank('C', 'إتقان الأنظمة اليومية', 'المستوى 10+'),
    _Rank('B', 'أداء متقدم ومستمر', 'المستوى 20+'),
    _Rank('A', 'توازن وإنجاز عاليان', 'المستوى 35+'),
    _Rank('S', 'إتقان النظام بالكامل', 'المستوى 50+'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchPlayerRank();
  }

  Future<void> _fetchPlayerRank() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _apiClient.getPlayerData();
      if (!mounted) return;
      final data = response.data;
      if (data is! Map || data['rank'] == null) {
        throw const FormatException(
            'Rank data was not returned by the server.');
      }
      final rank = data['rank'].toString().toUpperCase();
      if (!_ranks.any((item) => item.code == rank)) {
        throw FormatException('Unknown player rank: $rank');
      }
      setState(() {
        _currentRank = rank;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'تعذر تحميل بيانات الرتبة. تحقق من الاتصال ثم أعد المحاولة.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _ranks.indexWhere((rank) => rank.code == _currentRank);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('RANK LADDER // سُلّم الرتب')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                    children: [
                      SystemPanel(
                        active: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SystemTag('RANK PROGRESSION'),
                            const SizedBox(height: 12),
                            Text(
                              'رتبتك الحالية: $_currentRank',
                              style: const TextStyle(
                                color: AppColors.textMain,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${currentIndex + 1} / ${_ranks.length} مراتب مكتسبة',
                              style: const TextStyle(
                                color: AppColors.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var index = 0; index < _ranks.length; index++)
                        _buildRankStep(
                          _ranks[index],
                          isCurrent: index == currentIndex,
                          isUnlocked: index <= currentIndex,
                          isLast: index == _ranks.length - 1,
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildRankStep(
    _Rank rank, {
    required bool isCurrent,
    required bool isUnlocked,
    required bool isLast,
  }) {
    final color = isUnlocked ? AppColors.primary : AppColors.inactive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: ShapeDecoration(
                    color: isUnlocked
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.background,
                    shape: ChamferedBorder(
                      cut: 6,
                      dashed: !isUnlocked,
                      side: BorderSide(color: color, width: 1.2),
                    ),
                  ),
                  child: Icon(
                    isCurrent
                        ? Icons.radio_button_checked
                        : isUnlocked
                            ? Icons.check
                            : Icons.lock_outline,
                    color: color,
                    size: 13,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 72,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: isUnlocked
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : AppColors.inactive.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SystemPanel(
              active: isCurrent,
              dashed: !isUnlocked,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              child: Row(
                children: [
                  Text(
                    rank.code,
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rank.title,
                          style: TextStyle(
                            color: isUnlocked
                                ? AppColors.textMain
                                : AppColors.inactive,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'المتطلبات: ${rank.requirement}',
                          style: TextStyle(
                            color: isUnlocked
                                ? AppColors.textSub
                                : AppColors.inactive,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent) const SystemTag('ACTIVE', compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SystemPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SystemTag('CONNECTION ERROR', active: false),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSub),
              ),
              const SizedBox(height: 18),
              SystemButton(
                label: 'إعادة المحاولة',
                icon: Icons.refresh,
                onPressed: _fetchPlayerRank,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rank {
  const _Rank(this.code, this.title, this.requirement);

  final String code;
  final String title;
  final String requirement;
}
