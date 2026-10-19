import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _fetchTasks() async {
    try {
      final response = await _apiClient.getTasks();
      if (response.statusCode == 200) {
        setState(() {
          _tasks = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب المهام')),
        );
      }
    }
  }

  void _completeTask(int taskId) async {
    try {
      final response = await _apiClient.completeTask(taskId);
      if (response.statusCode == 200) {
        // إذا نجحت المهمة، نعرض رسالة XP
        int xpEarned = response.data['xp_earned'] ?? 10;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('أحسنت! +$xpEarned XP'), backgroundColor: AppColors.primary),
          );
        }
        // نعيد تحميل المهام لتحديث حالتها (لكننا سنبقيها بسيطة الآن)
        _fetchTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المهمة مكتملة بالفعل أو حدث خطأ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المهام اليومية')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      task['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      task['dimension'] == 'religion' ? 'الدين' :
                      task['dimension'] == 'body' ? 'الجسد' :
                      task['dimension'] == 'mind' ? 'العقل' :
                      task['dimension'] == 'work' ? 'العمل' :
                      task['dimension'] == 'self' ? 'النفس' : 'العلاقات',
                      style: const TextStyle(color: AppColors.textSub),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 30),
                      onPressed: () => _completeTask(task['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}