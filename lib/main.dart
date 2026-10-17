import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

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
      
      // دعم اللغة العربية (من اليمين لليسار)
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      home: const SplashScreen(),
    );
  }
}