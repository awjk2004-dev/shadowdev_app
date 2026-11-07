import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/chamfered_border.dart';
import '../../../core/design_system/system_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../home/providers/player_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  final Set<int> _completedTaskIds = {};

  static const Map<String, String> _dimensionLabels = {
    'mind': 'العقل',
    'body': 'الجسد',
    'work': 'العمل',
    'self': 'النفس',
    'self_development': 'النفس',
    'relations': 'العلاقات',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.getTasks();
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _tasks = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في جلب المهام')),
      );
    }
  }

  Future<void> _completeTask(int taskId) async {
    if (_completedTaskIds.contains(taskId)) return;

    // تحديث تفاؤلي فوري قبل انتظار استجابة الخادم
    setState(() => _completedTaskIds.add(taskId));

    try {
      final response = await _apiClient.completeTask(taskId);
      if (!mounted) return;

      final int xpEarned = response.data['xp_earned'] ?? 10;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أحسنت! +$xpEarned XP'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // تحديث بيانات اللاعب (XP والمستوى والسلسلة) في الواجهة الرئيسية
      context.read<PlayerProvider>().fetchPlayerData();
    } catch (e) {
      if (!mounted) return;

      // التراجع عن التحديث التفاؤلي عند فشل الطلب
      setState(() => _completedTaskIds.remove(taskId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المهمة مكتملة بالفعل أو حدث خطأ')),
      );
    }
  }

  void _deleteTask(int taskId) async {
    try {
      final response = await _apiClient.deleteTask(taskId);
      if (response.statusCode == 204) {
        _fetchTasks(); // تحديث القائمة بعد الحذف
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في حذف المهمة')),
        );
      }
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String selectedDimension = 'mind';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const ChamferedBorder(
                cut: 14,
                side: BorderSide(color: AppColors.primary),
              ),
              title: const Text('إضافة مهمة جديدة',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم المهمة',
                      labelStyle: TextStyle(color: AppColors.textSub),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButton<String>(
                    value: selectedDimension,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'mind', child: Text('العقل')),
                      DropdownMenuItem(value: 'body', child: Text('الجسد')),
                      DropdownMenuItem(value: 'work', child: Text('العمل')),
                      DropdownMenuItem(value: 'self', child: Text('النفس')),
                      DropdownMenuItem(
                          value: 'relations', child: Text('العلاقات')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDimension = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء',
                      style: TextStyle(color: AppColors.textSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      Navigator.pop(dialogContext);
                      try {
                        await _apiClient.createTask(
                            titleController.text, selectedDimension, 'daily');
                        if (!mounted) return;
                        await _fetchTasks(); // تحديث القائمة
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('تمت إضافة المهمة بنجاح!'),
                              backgroundColor: AppColors.primary),
                        );
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('فشل في إضافة المهمة')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DAILY QUESTS // المهام'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                _buildDailySummary(),
                const SizedBox(height: 14),
                if (_tasks.isEmpty)
                  SystemPanel(
                    dashed: true,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.checklist,
                          color: AppColors.inactive,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'لا توجد مهام بعد',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'أضف مهمة يومية لتبدأ تسجيل تقدمك.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSub),
                        ),
                        const SizedBox(height: 14),
                        SystemButton(
                          label: 'إضافة مهمة',
                          icon: Icons.add,
                          onPressed: _showAddTaskDialog,
                        ),
                      ],
                    ),
                  )
                else
                  for (final task in _tasks) _buildTaskCard(task),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: const ChamferedBorder(cut: 12),
          onPressed: _showAddTaskDialog,
          tooltip: 'إضافة مهمة',
          child: const Icon(PhosphorIconsRegular.plus),
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final completed = _completedTaskIds.length;
    final total = _tasks.length;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    return SystemPanel(
      active: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SystemTag('DAILY QUESTS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed / $total مكتملة',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'TOTAL $total',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

  Widget _buildTaskCard(dynamic task) {
    final int taskId = task['id'] as int;
    final bool isCompleted = _completedTaskIds.contains(taskId);
    final dimension = task['dimension']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(taskId.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.surfaceRaised,
          child: const Icon(
            PhosphorIconsRegular.trashSimple,
            color: AppColors.inactive,
          ),
        ),
        onDismissed: (_) => _deleteTask(taskId),
        child: SystemPanel(
          active: isCompleted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title']?.toString() ?? 'مهمة بدون اسم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? AppColors.textSub
                            : AppColors.textMain,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SystemTag(
                      _dimensionLabels[dimension] ?? dimension,
                      active: !isCompleted,
                      compact: true,
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isCompleted,
                onChanged: isCompleted ? null : (_) => _completeTask(taskId),
                activeColor: AppColors.primary,
                checkColor: AppColors.background,
                side: BorderSide(
                  color: isCompleted
                      ? AppColors.inactive
                      : AppColors.primary.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                shape: const ChamferedBorder(cut: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
