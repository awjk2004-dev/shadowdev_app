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
    'relations': 'العلاقات',
  };

  static const Map<String, int> _difficultyRewards = {
    'easy': 10,
    'medium': 25,
    'hard': 50,
  };

  static const Map<String, String> _difficultyLabels = {
    'easy': 'سهل',
    'medium': 'متوسط',
    'hard': 'صعب',
  };

  int _taskReward(dynamic task) {
    final savedReward = int.tryParse(task['xp_reward']?.toString() ?? '');
    if (savedReward != null) return savedReward;
    return _difficultyRewards[task['difficulty']?.toString()] ?? 10;
  }

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

      final task = _tasks.firstWhere((item) => item['id'] == taskId);
      final responseReward =
          response.data is Map ? response.data['xp_earned']?.toString() : null;
      final xpEarned = int.tryParse(responseReward ?? '') ?? _taskReward(task);

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

  Future<void> _deleteTask(int taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    setState(() => _tasks.removeAt(taskIndex));

    try {
      await _apiClient.deleteTask(taskId);
      if (!mounted) return;
      setState(() => _completedTaskIds.remove(taskId));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final restoreIndex =
            taskIndex < _tasks.length ? taskIndex : _tasks.length;
        _tasks.insert(restoreIndex, task);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في حذف المهمة')),
      );
    }
  }

  Future<void> _showEditTaskDialog(dynamic task) async {
    final taskId = task['id'] as int;
    final controller = TextEditingController(
      text: task['title']?.toString() ?? '',
    );
    final messenger = ScaffoldMessenger.of(context);
    var selectedDimension = task['dimension']?.toString() ?? 'mind';
    if (!_dimensionLabels.containsKey(selectedDimension)) {
      selectedDimension = 'mind';
    }
    var selectedDifficulty = task['difficulty']?.toString() ?? 'easy';
    if (!_difficultyRewards.containsKey(selectedDifficulty)) {
      selectedDifficulty = 'easy';
    }

    try {
      final updatedTask = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: const ChamferedBorder(
              cut: 14,
              side: BorderSide(color: AppColors.primary),
            ),
            title: const Text(
              'تعديل المهمة',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'اسم المهمة',
                    labelStyle: TextStyle(color: AppColors.textSub),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDimension,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items: _dimensionLabels.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDimension = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDifficulty,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'الصعوبة'),
                  items: _difficultyRewards.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            '${_difficultyLabels[entry.key]} '
                            '— ${entry.value} XP',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedDifficulty = value);
                    }
                  },
                ),
              ],
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
                onPressed: () {
                  final title = controller.text.trim();
                  if (title.isNotEmpty) {
                    Navigator.pop(dialogContext, {
                      'title': title,
                      'dimension': selectedDimension,
                      'difficulty': selectedDifficulty,
                    });
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      );

      if (updatedTask == null || !mounted) return;
      final title = updatedTask['title']!;
      final dimension = updatedTask['dimension']!;
      final difficulty = updatedTask['difficulty']!;
      final xpReward = _difficultyRewards[difficulty]!;

      await _apiClient.updateTask(
        taskId,
        title: title,
        dimension: dimension,
        difficulty: difficulty,
      );
      if (!mounted) return;

      setState(() {
        final index = _tasks.indexWhere((item) => item['id'] == taskId);
        if (index != -1) {
          final updatedTask = Map<String, dynamic>.from(_tasks[index] as Map);
          updatedTask['title'] = title;
          updatedTask['dimension'] = dimension;
          updatedTask['difficulty'] = difficulty;
          updatedTask['xp_reward'] = xpReward;
          _tasks[index] = updatedTask;
        }
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تعديل المهمة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('فشل في تعديل المهمة')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirmDeleteTask() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: const ChamferedBorder(
              cut: 14,
              side: BorderSide(color: Colors.redAccent),
            ),
            title: const Text(
              'حذف المهمة؟',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'لن تتمكن من استعادة هذه المهمة بعد حذفها.',
              style: TextStyle(color: AppColors.textSub),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: AppColors.textSub),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String selectedDimension = 'mind';
    String selectedDifficulty = 'easy';

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
                  DropdownButtonFormField<String>(
                    initialValue: selectedDimension,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'الفئة'),
                    items: _dimensionLabels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDimension = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDifficulty,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'الصعوبة'),
                    items: _difficultyRewards.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              '${_difficultyLabels[entry.key]} '
                              '— ${entry.value} XP',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDifficulty = value);
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
                      final difficulty = selectedDifficulty;
                      Navigator.pop(dialogContext);
                      try {
                        await _apiClient.createTask(
                          titleController.text.trim(),
                          selectedDimension,
                          'daily',
                          difficulty: difficulty,
                        );
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
                        const Text(
                          '[SYSTEM ALERT]',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'لا يوجد كويستات قائمة اليوم. '
                          'أضف مهمة جديدة لبدء التمرين.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
    final difficulty = task['difficulty']?.toString() ?? 'easy';
    final xpReward = _taskReward(task);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(taskId.toString()),
        direction: DismissDirection.horizontal,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.blue.withValues(alpha: 0.2),
          child: const Icon(
            Icons.edit,
            color: AppColors.primary,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.red.withValues(alpha: 0.2),
          child: const Icon(
            PhosphorIconsRegular.trashSimple,
            color: Colors.redAccent,
          ),
        ),
        confirmDismiss: (direction) async {
          final isRightToLeftSwipe =
              Directionality.of(context) == TextDirection.rtl
                  ? direction == DismissDirection.startToEnd
                  : direction == DismissDirection.endToStart;

          if (isRightToLeftSwipe) {
            await _showEditTaskDialog(task);
            return false;
          }

          return _confirmDeleteTask();
        },
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        SystemTag(
                          _dimensionLabels[dimension] ?? dimension,
                          active: !isCompleted,
                          compact: true,
                        ),
                        SystemTag(
                          '${_difficultyLabels[difficulty] ?? 'سهل'} • '
                          '$xpReward XP',
                          active: !isCompleted,
                          compact: true,
                        ),
                      ],
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
