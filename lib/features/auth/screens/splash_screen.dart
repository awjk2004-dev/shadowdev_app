import 'package:flutter/material.dart';

import '../../../core/design_system/system_widgets.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.terminal, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'SHADOWDEV // SYSTEM ONLINE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SystemPanel(
                active: true,
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    SystemTag('SYSTEM ALERT'),
                    SizedBox(height: 28),
                    Icon(
                      Icons.radar,
                      color: AppColors.primary,
                      size: 64,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'لقد تم اختيارك كلاعب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 30,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'نظام النهوض جاهز. ابدأ مهمتك الأولى.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SystemButton(
                label: 'ابدأ النهوض',
                icon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'نظام شخصي — تقدمك يبدأ بخطوة',
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
