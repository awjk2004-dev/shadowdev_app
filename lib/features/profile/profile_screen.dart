import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/design_system/chamfered_border.dart';
import '../../../core/design_system/system_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../auth/screens/login_screen.dart';
import '../ranks/ranks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String _username = '';
  String _fullName = '';
  String _rank = 'E';
  double _targetWeight = 0.0;
  Map<String, int> _stats = {
    'body': 0,
    'mind': 0,
    'work': 0,
    'self_development': 0,
    'relations': 0,
  };

  final List<Map<String, dynamic>> _statItems = const [
    {
      'key': 'mind',
      'label': 'العقل',
      'icon': PhosphorIconsRegular.brain,
    },
    {
      'key': 'body',
      'label': 'الجسد',
      'icon': PhosphorIconsRegular.barbell,
    },
    {
      'key': 'work',
      'label': 'العمل',
      'icon': PhosphorIconsRegular.briefcase,
    },
    {
      'key': 'self_development',
      'label': 'النفس',
      'icon': PhosphorIconsRegular.shield,
    },
    {
      'key': 'relations',
      'label': 'العلاقات',
      'icon': PhosphorIconsRegular.heart,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        _apiClient.getUserData(),
        _apiClient.getWeeklyStats(),
      ]);
      if (!mounted) return;

      final userData = responses[0].data is Map
          ? Map<String, dynamic>.from(responses[0].data as Map)
          : <String, dynamic>{};
      final statsData = responses[1].data is Map
          ? Map<String, dynamic>.from(responses[1].data as Map)
          : <String, dynamic>{};

      Map<String, dynamic> playerData = <String, dynamic>{};
      try {
        final playerResponse = await _apiClient.getPlayerData();
        if (playerResponse.data is Map) {
          playerData = Map<String, dynamic>.from(playerResponse.data as Map);
        }
      } catch (_) {
        // تظل بيانات الملف الشخصي متاحة حتى لو تعذر جلب بيانات اللاعب
      }

      if (!mounted) return;
      setState(() {
        _username = userData['username']?.toString() ?? '';
        _fullName = userData['full_name']?.toString() ?? '';
        _rank = playerData['rank']?.toString() ?? 'E';
        _targetWeight = _asDouble(playerData['target_weight']);
        _stats = {
          'body': _asInt(statsData['body']),
          'mind': _asInt(statsData['mind']),
          'work': _asInt(statsData['work']),
          'self_development': _asInt(
            statsData['self_development'] ?? statsData['self'],
          ),
          'relations': _asInt(statsData['relations']),
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر جلب بيانات الملف الشخصي')),
      );
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showReminderSettings() async {
    final service = LocalNotificationService.instance;
    final currentReminder = await service.getReminderTime();
    if (!mounted) return;

    var enabled = currentReminder.enabled;
    var reminderTime = TimeOfDay(
      hour: currentReminder.hour,
      minute: currentReminder.minute,
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const ChamferedBorder(
            cut: 14,
            side: BorderSide(color: AppColors.primary),
          ),
          title: const Text(
            'التذكير اليومي',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'تفعيل إشعار يومي',
                  style: TextStyle(color: AppColors.textMain),
                ),
                value: enabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => enabled = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'وقت التذكير',
                  style: TextStyle(color: AppColors.textMain),
                ),
                trailing: Text(
                  reminderTime.format(dialogContext),
                  style: const TextStyle(color: AppColors.primary),
                ),
                enabled: enabled,
                onTap: !enabled
                    ? null
                    : () async {
                        final selectedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: reminderTime,
                        );
                        if (!dialogContext.mounted) return;
                        if (selectedTime != null) {
                          setDialogState(() => reminderTime = selectedTime);
                        }
                      },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSub),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true || !mounted) return;

    try {
      if (enabled) {
        final scheduled = await service.enableDailyReminder(
          hour: reminderTime.hour,
          minute: reminderTime.minute,
        );
        if (!mounted) return;
        if (!scheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'لم يتم منح صلاحية الإشعارات. فعّلها من إعدادات الجهاز.'),
            ),
          );
          return;
        }
      } else {
        await service.disableDailyReminder();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'تم تفعيل التذكير اليومي' : 'تم إيقاف التذكير اليومي',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ إعداد التذكير')),
      );
    }
  }

  void _editNameDialog() {
    final controller = TextEditingController(text: _fullName);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: ChamferedBorder(
            cut: 14,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          title: const Text(
            'تعديل الاسم',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الاسم الكامل',
              labelStyle: const TextStyle(color: AppColors.textSub),
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSub),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                Navigator.pop(dialogContext);
                try {
                  await _apiClient.updateProfile(newName);
                  if (!mounted) return;
                  setState(() => _fullName = newName);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('تم تحديث الاسم بنجاح!')),
                  );
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('فشل التحديث')),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _editTargetWeightDialog() {
    final controller = TextEditingController(
      text: _targetWeight > 0 ? _targetWeight.toStringAsFixed(1) : '',
    );
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: ChamferedBorder(
            cut: 14,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          title: const Text(
            'تعديل الوزن المستهدف',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الوزن المستهدف بالكيلوجرام',
              labelStyle: const TextStyle(color: AppColors.textSub),
              suffixText: 'كجم',
              suffixStyle: const TextStyle(color: AppColors.textSub),
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSub),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newTarget = double.tryParse(controller.text.trim());
                if (newTarget == null || newTarget <= 0) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال وزن مستهدف صحيح'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await _apiClient.updateTargetWeight(newTarget);
                  if (!mounted) return;
                  setState(() => _targetWeight = newTarget);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الوزن المستهدف بنجاح!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('فشل تحديث الوزن المستهدف'),
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('نافذة الحالة'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 28),
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildTargetWeightButton(),
                    const SizedBox(height: 20),
                    _buildMenuButton(
                      icon: PhosphorIconsRegular.medal,
                      title: 'سُلّم الرتب',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RanksScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuButton(
                      icon: PhosphorIconsRegular.pencilSimple,
                      title: 'تعديل الاسم',
                      onTap: _editNameDialog,
                    ),
                    _buildMenuButton(
                      icon: PhosphorIconsRegular.bell,
                      title: 'إعداد التذكير اليومي',
                      onTap: _showReminderSettings,
                    ),
                    _buildMenuButton(
                      icon: PhosphorIconsRegular.signOut,
                      title: 'تسجيل الخروج',
                      color: AppColors.inactive,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: const CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surface,
            child: Icon(
              PhosphorIconsRegular.user,
              size: 56,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _fullName.isEmpty ? 'اللاعب' : _fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@$_username',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 12),
        SystemTag('$_rank-RANK'),
      ],
    );
  }

  Widget _buildStatsCard() {
    final maxStat = _statItems.fold<int>(0, (currentMax, item) {
      final value = _stats[item['key']] ?? 0;
      return value > currentMax ? value : currentMax;
    });
    final denominator = maxStat > 0 ? maxStat : 1;

    return _SystemCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                PhosphorIconsRegular.chartLine,
                color: AppColors.accent,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'إحصائيات الأسبوع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._statItems.map((item) {
            final value = _stats[item['key']] ?? 0;
            final progress = (value / denominator).clamp(0.0, 1.0).toDouble();
            return _buildStatRow(item, value, progress);
          }),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    Map<String, dynamic> item,
    int value,
    double progress,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetWeightButton() {
    final label = _targetWeight > 0
        ? 'تعديل الوزن المستهدف (${_targetWeight.toStringAsFixed(1)} كجم)'
        : 'تحديد الوزن المستهدف';

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _editTargetWeightDialog,
        icon: const Icon(
          PhosphorIconsRegular.target,
          color: AppColors.accent,
          size: 22,
        ),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: const ChamferedBorder(cut: 12),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        shape: ChamferedBorder(
          cut: 11,
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const ChamferedBorder(cut: 11),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color == AppColors.inactive ? color : AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            PhosphorIconsRegular.caretLeft,
            color: AppColors.textSub,
            size: 22,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SystemPanel(child: child);
  }
}
