import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../features/home/screens/home_screen.dart'; // سننشئها لاحقاً
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.statusCode == 200) {
        // حفظ التوكن
        await _storage.write(
            key: 'access_token', value: response.data['access_token']);

        // الانتقال للشاشة الرئيسية (سنقوم بإنشائها)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeScreen()), // صفحة مؤقتة
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('اسم المستخدم أو كلمة المرور غير صحيحة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية (صورة الفارس)
          Positioned.fill(
            child: Image.asset(
              'assets/images/knight_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: AppColors.background),
            ),
          ),

          // 2. طبقة تعتيم (لكي تظهر النصوص)
          Positioned.fill(
            child: Container(
              color: AppColors.background.withValues(alpha: 0.85),
            ),
          ),

          // 3. المحتوى
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 32),

                    // حقل اسم المستخدم
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم',
                        labelStyle: const TextStyle(color: AppColors.textSub),
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.person, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // حقل كلمة المرور
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        labelStyle: const TextStyle(color: AppColors.textSub),
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon:
                            const Icon(Icons.lock, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // زر الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('دخول',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('ليس لديك حساب؟ إنشاء حساب'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
