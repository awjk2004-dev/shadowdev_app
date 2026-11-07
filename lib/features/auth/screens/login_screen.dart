import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/design_system/system_widgets.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../../features/home/screens/home_screen.dart';
import '../../../features/home/providers/player_provider.dart';
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

        if (mounted) {
          context.read<PlayerProvider>().fetchPlayerData();
        }

        // الانتقال للشاشة الرئيسية (سنقوم بإنشائها)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeScreen()), // صفحة مؤقتة
          );
        }
      }
    } on DioException catch (e) {
      String message;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          message =
              'تعذر الاتصال بالخادم. تأكد أن الباك اند يعمل وأن الهاتف على نفس الشبكة.';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            message = 'اسم المستخدم أو كلمة المرور غير صحيحة';
          } else {
            message = 'خطأ من الخادم (${e.response?.statusCode})';
          }
          break;
        default:
          message = 'حدث خطأ أثناء تسجيل الدخول';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')),
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
                  const SystemTag('SYSTEM ACCESS'),
                  const SizedBox(height: 22),
                  const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل بيانات اللاعب للمتابعة إلى النظام.',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 28),
                  SystemPanel(
                    active: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const SystemTag('PLAYER AUTHENTICATION', compact: true),
                        const SizedBox(height: 20),
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
                          label: 'دخول إلى النظام',
                          icon: Icons.login,
                          busy: _isLoading,
                          onPressed: _login,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'ليس لديك حساب؟ إنشاء حساب',
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
