import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

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
        title: const Text('المهام اليومية'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final int taskId = task['id'] as int;
                final bool isCompleted = _completedTaskIds.contains(taskId);

                return Dismissible(
                  key: Key(task['id'].toString()),
                  direction:
                      DismissDirection.endToStart, // السحب من اليسار لليمين
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(
                      PhosphorIconsRegular.trashSimple,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    _deleteTask(task['id']);
                  },
                  child: Card(
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.textSub : Colors.white,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        _dimensionLabels[task['dimension']] ??
                            task['dimension'].toString(),
                        style: const TextStyle(color: AppColors.textSub),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isCompleted
                              ? PhosphorIconsFill.checkCircle
                              : PhosphorIconsRegular.checkCircle,
                          color: isCompleted
                              ? AppColors.accent
                              : AppColors.primary,
                          size: 30,
                        ),
                        onPressed:
                            isCompleted ? null : () => _completeTask(taskId),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: _showAddTaskDialog,
          child: const Icon(
            PhosphorIconsRegular.plus,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
