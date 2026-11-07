import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/design_system/system_widgets.dart';
import '../../../core/network/api_client.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _apiClient = ApiClient();

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_usernameController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.register(
        _usernameController.text.trim(),
        _fullNameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      String errorMsg = 'حدث خطأ أثناء التسجيل';
      if (e is DioException) {
        if (e.response != null && e.response?.data != null) {
          var data = e.response!.data;
          if (data is Map && data.containsKey('detail')) {
            errorMsg = data['detail'].toString();
          } else {
            errorMsg = 'خطأ من السيرفر: ${e.response!.statusCode}';
          }
        } else {
          errorMsg = 'لا يمكن الاتصال بالخادم. تأكد من الشبكة.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SystemTag('NEW PLAYER'),
                  const SizedBox(height: 22),
                  const Text(
                    'انضم إلى النظام',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أنشئ ملف اللاعب وابدأ بناء تقدمك.',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 28),
                  SystemPanel(
                    active: true,
                    child: Column(
                      children: [
                        SystemTextField(
                          controller: _fullNameController,
                          label: 'الاسم الكامل',
                          icon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        SystemTextField(
                          controller: _usernameController,
                          label: 'اسم المستخدم',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        SystemTextField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 24),
                        SystemButton(
                          label: 'إنشاء حساب',
                          icon: Icons.person_add_alt_1,
                          busy: _isLoading,
                          onPressed: _register,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'لديك حساب بالفعل؟ سجل الدخول',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
