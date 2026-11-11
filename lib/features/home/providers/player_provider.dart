import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/streak_home_widget_service.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  int xp = 0;
  int level = 1;
  String rank = 'E';
  int xpToNextLevel = 100;
  int tasksCompleted = 0;
  int tasksTotal = 0;
  int currentStreak = 0;
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> stats = {
    'body': 0,
    'mind': 0,
    'work': 0,
    'self_development': 0,
    'relations': 0,
  };

  int _asInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _updateStreakWidget(int streakDays) async {
    try {
      await StreakHomeWidgetService.updateStreak(streakDays);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'streak home widget',
        ),
      );
    }
  }

  Future<void> fetchPlayerData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final playerResponse = await _apiClient.getPlayerData();
      final rawPlayerData = playerResponse.data;
      if (rawPlayerData is! Map) {
        throw const FormatException('Invalid player response');
      }
      final playerData = Map<String, dynamic>.from(rawPlayerData);

      xp = playerData['xp'] as int? ?? xp;
      level = playerData['level'] as int? ?? level;
      rank = playerData['rank'] as String? ?? rank;
      xpToNextLevel = playerData['xp_to_next_level'] == null
          ? 100
          : (_asInt(playerData['xp_to_next_level']) > 0
              ? _asInt(playerData['xp_to_next_level'])
              : 100);

      try {
        final streakResponse = await _apiClient.getStreakData();
        final rawStreakData = streakResponse.data;
        if (rawStreakData is! Map) {
          throw const FormatException('Invalid streak response');
        }
        final streakData = Map<String, dynamic>.from(rawStreakData);
        final streak = streakData['current_streak'] ?? streakData['streak'];
        currentStreak = streak is int ? streak : currentStreak;
        tasksCompleted = _asInt(streakData['tasks_completed']);
        tasksTotal = _asInt(streakData['tasks_total']);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'player streak loading',
          ),
        );
      }
      await _updateStreakWidget(currentStreak);

      try {
        final statsResponse = await _apiClient.getStats();
        final statsData = statsResponse.data as Map<String, dynamic>? ?? {};
        stats = {
          'body': _asInt(statsData['body']),
          'mind': _asInt(statsData['mind']),
          'work': _asInt(statsData['work']),
          'self_development': _asInt(
            statsData['self_development'] ?? statsData['self'],
          ),
          'relations': _asInt(statsData['relations']),
        };
      } catch (_) {
        // تظل بيانات اللاعب والسلسلة متاحة حتى لو تعذر جلب الإحصائيات
      }
    } catch (error, stackTrace) {
      errorMessage = _playerLoadErrorMessage(error);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'player data loading',
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _playerLoadErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'انتهت صلاحية تسجيل الدخول أو لا يملك الحساب صلاحية الوصول. سجّل الدخول مجددًا.';
      }
      if (statusCode == 404) {
        return 'لم يعثر الخادم على بيانات اللاعب لهذا الحساب.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'حدث خطأ داخل الخادم ($statusCode). تحقق من تطبيق تحديثات الباك إند وقاعدة البيانات.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'تعذر الاتصال بالخادم. تحقق من الإنترنت وعنوان الخادم ثم حاول مجددًا.';
      }
      if (statusCode != null) {
        return 'رفض الخادم جلب بيانات اللاعب (HTTP $statusCode).';
      }
    }

    if (error is FormatException) {
      return 'استجابة بيانات اللاعب من الخادم غير مكتملة أو غير متوافقة.';
    }

    return 'تعذر جلب بيانات اللاعب بسبب خطأ غير متوقع.';
  }
}
