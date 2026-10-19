import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  
  // بيانات اللاعب والوزن
  double _currentWeight = 0.0;
  double _targetWeight = 50.0;
  String _bmiCategory = 'غير محدد';
  double _bmiValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchBodyData();
  }

  void _fetchBodyData() async {
    setState(() => _isLoading = true);
    try {
      // 1. جلب الوزن
      final weightRes = await _apiClient.getWeightData();
      if (weightRes.statusCode == 200) {
        _currentWeight = double.tryParse(weightRes.data['current_weight'].toString()) ?? 0.0;
        _targetWeight = double.tryParse(weightRes.data['target_weight'].toString()) ?? 50.0;
      }

      // 2. جلب الـ BMI
      final bmiRes = await _apiClient.getBmi();
      if (bmiRes.statusCode == 200 && bmiRes.data['bmi'] != null) {
        _bmiValue = double.tryParse(bmiRes.data['bmi'].toString()) ?? 0.0;
        _bmiCategory = bmiRes.data['category'] ?? 'غير محدد';
      } else {
        _bmiCategory = 'أدخل طولك أولاً';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في جلب بيانات الجسد')),
        );
      }
    }
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('تسجيل وزن جديد', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الوزن بالكيلوجرام',
              labelStyle: const TextStyle(color: AppColors.textSub),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textSub)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: AppColors.textSub, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final weight = double.tryParse(controller.text);
                      if (weight != null) {
                        Navigator.pop(context);
                        try {
                          await _apiClient.recordWeight(weight);
                          _fetchBodyData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تسجيل الوزن بنجاح!'), backgroundColor: AppColors.primary),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشل في الاتصال بالسيرفر')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('تسجيل الطول', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الطول بالمتر (مثال: 1.75)',
              labelStyle: const TextStyle(color: AppColors.textSub),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textSub)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: AppColors.textSub, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final height = double.tryParse(controller.text);
                      if (height != null) {
                        Navigator.pop(context);
                        try {
                          await _apiClient.updateHeight(height);
                          _fetchBodyData(); // تحديث الـ BMI
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تحديث الطول بنجاح!'), backgroundColor: AppColors.primary),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('فشل في الاتصال بالسيرفر')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // حساب النسبة المئوية للوزن
    double progress = 0.0;
    if (_targetWeight > 43.0) {
      progress = _currentWeight / _targetWeight;
    } else {
      progress = 43.0 / _currentWeight;
    }
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مهمة الجسد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchBodyData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 1. بطاقة الوزن
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'وزن القوة',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _currentWeight > 0 ? _currentWeight.toStringAsFixed(1) : '--',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Text('كيلوجرام', style: TextStyle(color: AppColors.textSub)),
                        const SizedBox(height: 20),
                        
                        // شريط التقدم
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_currentWeight > 0 ? '$_currentWeight كجم' : '0 كجم', style: const TextStyle(color: AppColors.textSub)),
                            Text('$_targetWeight كجم', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. بطاقة الـ BMI
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('مؤشر كتلة الجسم (BMI)', style: TextStyle(color: Colors.white, fontSize: 16)),
                                const SizedBox(height: 5),
                                Text(
                                  _bmiCategory,
                                  style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  _bmiValue > 0 ? _bmiValue.toStringAsFixed(1) : '؟',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _showAddHeightDialog,
                          child: const Text('إضافة/تعديل الطول', style: TextStyle(color: AppColors.accent, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. زر تسجيل وزن
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('سجل وزنك الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      onPressed: _showAddWeightDialog,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}