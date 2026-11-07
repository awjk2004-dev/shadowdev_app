import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/streak_home_widget_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/providers/player_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/skills/providers/skill_tree_provider.dart';

@pragma('vm:entry-point')
Future<void> _handleWidgetInteraction(Uri? uri) async {
  if (uri?.host != 'refresh') return;

  try {
    final response = await ApiClient().getStreakData();
    final streakData = response.data;
    if (streakData is! Map) {
      throw const FormatException('Unexpected streak response');
    }

    final rawStreak = streakData['current_streak'] ?? streakData['streak'];
    final streak = rawStreak is num
        ? rawStreak.toInt()
        : int.tryParse(rawStreak?.toString() ?? '');
    if (streak == null) {
      throw const FormatException('Streak value is missing');
    }

    await StreakHomeWidgetService.updateStreak(
      streak,
      systemMessage: 'تم التحديث',
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'streak widget refresh',
      ),
    );
    await HomeWidget.saveWidgetData<String>(
      'system_message',
      'تعذر التحديث',
    );
    await HomeWidget.updateWidget(
      name: 'StreakWidgetProvider',
      androidName: 'StreakWidgetProvider',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await HomeWidget.registerInteractivityCallback(_handleWidgetInteraction);
    await LocalNotificationService.instance.initialize();
    await LocalNotificationService.instance.restoreDailyReminder();
  }
  runApp(const ShadowDevApp());
}

class ShadowDevApp extends StatelessWidget {
  const ShadowDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PlayerProvider()..fetchPlayerData(),
        ),
        ChangeNotifierProvider(
          create: (_) => SkillTreeProvider(),
        ),
      ],
      child: MaterialApp(
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
      ),
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
            body: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
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
