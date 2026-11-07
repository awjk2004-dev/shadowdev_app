import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class StreakHomeWidgetService {
  const StreakHomeWidgetService._();

  static Future<void> updateStreak(
    int streakDays, {
    String systemMessage = 'النظام مستيقظ',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final weekdayIndex = (DateTime.now().weekday + 1) % 7;
    await HomeWidget.saveWidgetData<int>(
      'streak_count',
      streakDays < 0 ? 0 : streakDays,
    );
    await HomeWidget.saveWidgetData<String>(
      'system_message',
      systemMessage,
    );
    await HomeWidget.saveWidgetData<int>('weekday_index', weekdayIndex);
    await HomeWidget.updateWidget(
      name: 'StreakWidgetProvider',
      androidName: 'StreakWidgetProvider',
    );
  }
}
