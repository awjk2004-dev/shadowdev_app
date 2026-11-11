import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../home/providers/player_provider.dart';
import '../skills/providers/skill_tree_provider.dart';
import 'body_metrics.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen>
    with AutomaticKeepAliveClientMixin {
  final _apiClient = ApiClient();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  bool _isSaving = false;

  double _currentWeight = 0.0;
  double _targetWeight = 0.0;
  double _startWeight = 0.0;
  double _bmiValue = 0.0;
  String _bmiCategory = 'غير محدد';

  bool get _needsSetup => _currentWeight <= 0 || _targetWeight <= 0;

  double get _progress {
    if (_currentWeight <= 0 || _targetWeight <= 0) return 0.0;
    if (_startWeight <= 0) return 0.0;

    final difference = _targetWeight - _startWeight;
    if (difference.abs() < 0.01) {
      return _currentWeight >= _targetWeight ? 1.0 : 0.0;
    }

    final value = (_currentWeight - _startWeight) / difference;
    return value.clamp(0.0, 1.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _fetchBodyData();
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _fetchBodyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final playerRes = await _apiClient.getWeightData();
      if (!mounted) return;

      final playerData = playerRes.data is Map
          ? Map<String, dynamic>.from(playerRes.data as Map)
          : <String, dynamic>{};

      final currentWeight = _toDouble(playerData['current_weight']);
      final targetWeight = _toDouble(playerData['target_weight']);
      final startWeight = _toDouble(playerData['start_weight']);

      double bmiValue = 0.0;
      String bmiCategory = 'أدخل طولك أولاً';

      try {
        final bmiRes = await _apiClient.getBmi();
        if (!mounted) return;

        final bmiData = bmiRes.data is Map
            ? Map<String, dynamic>.from(bmiRes.data as Map)
            : <String, dynamic>{};

        bmiValue = _toDouble(bmiData['bmi']);
        bmiCategory = bmiData['category'] as String? ??
            bmiData['message'] as String? ??
            'أدخل طولك أولاً';
      } catch (_) {
        // تبقى بيانات الوزن متاحة حتى لو تعذر حساب BMI
      }

      final height = _toDouble(playerData['height']);
      final calculatedBmi = BodyMetrics.calculateBmi(
        weightKg: currentWeight,
        height: height,
      );
      if (calculatedBmi != null) {
        bmiValue = calculatedBmi;
        bmiCategory = BodyMetrics.categoryForBmi(calculatedBmi);
      } else if (bmiValue > 0) {
        bmiCategory = BodyMetrics.categoryForBmi(bmiValue);
      }

      if (!mounted) return;
      setState(() {
        _currentWeight = currentWeight;
        _targetWeight = targetWeight;
        _startWeight = startWeight;
        _bmiValue = bmiValue;
        _bmiCategory = bmiCategory;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في جلب بيانات الجسد')),
      );
    }
  }

  Future<void> _saveInitialWeights() async {
    final playerProvider = context.read<PlayerProvider>();
    final skillTreeProvider = context.read<SkillTreeProvider>();
    final currentWeight = double.tryParse(_currentWeightController.text.trim());
    final targetWeight = double.tryParse(_targetWeightController.text.trim());

    if (currentWeight == null ||
        targetWeight == null ||
        currentWeight <= 0 ||
        targetWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال أرقام صحيحة للوزن')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _apiClient.recordWeight(currentWeight);
      await _apiClient.updateTargetWeight(targetWeight);
      if (!mounted) return;

      await Future.wait([
        _fetchBodyData(),
        playerProvider.fetchPlayerData(),
        skillTreeProvider.fetchSkills(),
      ]);
      if (!mounted) return;

      _currentWeightController.clear();
      _targetWeightController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات الوزن بنجاح!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في حفظ بيانات الوزن، حاول مرة أخرى'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مهمة الجسد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchBodyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _needsSetup
              ? _buildSetupForm()
              : _buildBodyContent(),
    );
  }

  Widget _buildSetupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'إعداد بيانات الوزن',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل وزنك الحالي ووزنك المستهدف لنبدأ رحلتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _currentWeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الوزن الحالي',
                    labelStyle: const TextStyle(color: AppColors.textSub),
                    suffixText: 'كجم',
                    suffixStyle: const TextStyle(color: AppColors.textSub),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.6),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.textSub.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetWeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الوزن المستهدف',
                    labelStyle: const TextStyle(color: AppColors.textSub),
                    suffixText: 'كجم',
                    suffixStyle: const TextStyle(color: AppColors.textSub),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.6),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.textSub.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveInitialWeights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'حفظ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final progress = _progress;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'وزن القوة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currentWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'كيلوجرام',
                  style: TextStyle(color: AppColors.textSub),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_currentWeight.toStringAsFixed(1)} كجم',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSub),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_targetWeight.toStringAsFixed(1)} كجم',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مؤشر كتلة الجسم (BMI)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _bmiCategory,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _bmiValue > 0
                                  ? _bmiValue.toStringAsFixed(1)
                                  : '؟',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _showAddHeightDialog,
                  child: const Text(
                    'إضافة/تعديل الطول',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'سجل وزنك الآن',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _showAddWeightDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'تسجيل وزن جديد',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'الوزن بالكيلوجرام',
              labelStyle: TextStyle(color: AppColors.textSub),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textSub),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final playerProvider = context.read<PlayerProvider>();
                      final skillTreeProvider =
                          context.read<SkillTreeProvider>();
                      final weight = double.tryParse(controller.text);
                      if (weight != null && weight > 0) {
                        Navigator.pop(dialogContext);
                        try {
                          await _apiClient.recordWeight(weight);
                          if (!mounted) return;
                          await Future.wait([
                            _fetchBodyData(),
                            playerProvider.fetchPlayerData(),
                            skillTreeProvider.fetchSkills(),
                          ]);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('تم تسجيل الوزن بنجاح!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('فشل في الاتصال بالسيرفر'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddHeightDialog() {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'تسجيل الطول',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'الطول بالمتر (مثال: 1.75)',
              labelStyle: TextStyle(color: AppColors.textSub),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textSub),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final height = double.tryParse(controller.text);
                      if (height != null && height > 0) {
                        Navigator.pop(dialogContext);
                        try {
                          await _apiClient.updateHeight(height);
                          if (!mounted) return;
                          await _fetchBodyData();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث الطول بنجاح!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('فشل في الاتصال بالسيرفر'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'حفظ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
