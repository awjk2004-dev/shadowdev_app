import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const ShadowDevApp());
}

class ShadowDevApp extends StatelessWidget {
  const ShadowDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShadowDev',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      // 👇 هنا المنطق الذكي: نستخدم FutureBuilder لفحص التوكن
      home: const _AuthCheck(),
    );
  }
}

// شاشة فحص (Router)
class _AuthCheck extends StatelessWidget {
  const _AuthCheck();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: const FlutterSecureStorage().read(key: 'access_token'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // شاشة تحميل سريعة جداً (نصف ثانية)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        // إذا كان هناك توكن محفوظ (مستخدم قديم)
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // إذا لم يوجد توكن (مستخدم جديد)
        return const SplashScreen();
      },
    );
  }
}