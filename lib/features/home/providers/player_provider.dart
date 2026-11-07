import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/streak_home_widget_service.dart';

class PlayerProvider extends ChangeNotifier {
  PlayerProvider({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  int xp = 0;
  int level = 1;
  String rank = 'E';
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
      final responses = await Future.wait([
        _apiClient.getPlayerData(),
        _apiClient.getStreakData(),
      ]);

      final playerData = responses[0].data as Map<String, dynamic>? ?? {};
      final streakData = responses[1].data as Map<String, dynamic>? ?? {};

      xp = playerData['xp'] as int? ?? xp;
      level = playerData['level'] as int? ?? level;
      rank = playerData['rank'] as String? ?? rank;

      final streak = streakData['current_streak'] ?? streakData['streak'];
      currentStreak = streak is int ? streak : currentStreak;
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
    } catch (_) {
      errorMessage = 'تعذر جلب بيانات اللاعب، يرجى المحاولة مرة أخرى';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
