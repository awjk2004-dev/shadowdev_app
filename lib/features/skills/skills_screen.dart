import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _skills = [];

  @override
  void initState() {
    super.initState();
    _fetchSkills();
  }

  void _fetchSkills() async {
    try {
      final response = await _apiClient.getSkills();
      if (response.statusCode == 200) {
        setState(() {
          _skills = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب المهارات')),
        );
      }
    }
  }

  void _upgradeSkill(int skillId) async {
    try {
      final response = await _apiClient.upgradeSkill(skillId);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت الترقية بنجاح!'), backgroundColor: AppColors.primary),
          );
        }
        _fetchSkills(); // تحديث القائمة
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن الترقية (قد تكون وصلت للحد الأقصى)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('شجرة المهارات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _skills.length,
              itemBuilder: (context, index) {
                final skill = _skills[index];
                final status = skill['status'];
                final isWarrior = status == 'warrior';
                
                // تحديد الأيقونة واللون حسب الحالة
                IconData icon;
                Color iconColor;
                String statusText;

                if (status == 'beginner') {
                  icon = Icons.star_border;
                  iconColor = AppColors.textSub;
                  statusText = 'مبتدئ';
                } else if (status == 'practitioner') {
                  icon = Icons.star_half;
                  iconColor = Colors.orangeAccent;
                  statusText = 'ممارس';
                } else {
                  icon = Icons.star;
                  iconColor = AppColors.accent;
                  statusText = 'محارب';
                }

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(icon, color: iconColor, size: 32),
                    title: Text(
                      skill['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                    ),
                    subtitle: Text(
                      'المرحلة ${skill['stage']} • $statusText',
                      style: TextStyle(color: isWarrior ? AppColors.accent : AppColors.textSub),
                    ),
                    trailing: isWarrior
                        ? const Icon(Icons.check_circle, color: AppColors.accent, size: 30)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _upgradeSkill(skill['skill_id']),
                            child: const Text('ترقية'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}