import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: const RadialGradient(
            colors: const [AppColors.surface, AppColors.background],
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. مساحة علوية لدفع العناصر للنصف
              const Spacer(flex: 2),

              // 2. الشعار
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.shield, size: 120, color: AppColors.primary);
                },
              ),
              
              const SizedBox(height: 30),

              // 3. النصوص
              const Text(
                'SHADOWDEV // نظام النهوض',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'لقد تم اختيارك كـ لاعب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'نظام النهوض — الظل يرتقي',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                ),
              ),

              // 4. مساحة مرنة لدفع الزر لأسفل
              const Spacer(flex: 3),

              // 5. الزر
              SizedBox(
                width: 280,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white, // 👈 إجبار النص على اللون الأبيض
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 15, 
                    shadowColor: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سننتقل لشاشة الدخول قريباً!')),
                    );
                  },
                  child: const Text(
                    'ابدأ النهوض',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 👈 تأكيد إضافي للون الأبيض
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40), // مسافة قبل النص السفلي

              // 6. نص أسفل الشاشة
              const Text(
                'نظام شخصي يعمل دون اتصال',
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}