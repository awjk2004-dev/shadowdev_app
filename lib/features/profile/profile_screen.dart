import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../auth/screens/login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() async {
    try {
      final response = await _apiClient.getPlayerData(); // نجلب البيانات الأساسية
      // ملاحظة: في الباك اند الحقيقي، يجب أن تجلب بيانات المستخدم من /auth/me
      // هنا سنستخدم بيانات وهمية أو نجلبها من التخزين المحلي مؤقتاً
      setState(() {
        _username = 'ahmed'; // سيتم جلبها ديناميكياً لاحقاً
        _fullName = 'Ahmed Ali';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _storage.delete(key: 'access_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _editNameDialog() {
    final controller = TextEditingController(text: _fullName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('تعديل الاسم', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              labelStyle: TextStyle(color: AppColors.textSub),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _apiClient.updateProfile(controller.text);
                  setState(() => _fullName = controller.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث الاسم بنجاح!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // الصورة الشخصية
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  
                  // الاسم
                  Text(
                    _fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '@$_username',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 40),

                  // زر تعديل الاسم
                  ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text('تعديل الاسم الكامل', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSub, size: 16),
                    onTap: _editNameDialog,
                  ),
                  const SizedBox(height: 10),

                  // زر تسجيل الخروج
                  ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
    );
  }
}