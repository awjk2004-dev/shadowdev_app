import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // يمكن تجاوزه وقت البناء عبر:
  // flutter run --dart-define=API_URL=http://<HOST_IP>:8000/api/v1
  //
  // ملاحظة: على الهاتف الحقيقي لا يعمل localhost لأنه يشير إلى الهاتف نفسه،
  // لذلك نستخدم عنوان الكمبيوتر على الشبكة المحلية.
  static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://shadowdev-backend.onrender.com/api/v1',
  );
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // 1. المصادقة (Auth)
  Future<Response> login(String username, String password) async {
    return await _dio.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<Response> register(
      String username, String fullName, String password) async {
    return await _dio.post('/auth/register', data: {
      'username': username,
      'full_name': fullName,
      'password': password,
    });
  }

  Future<Response> updateProfile(String fullName) async {
    return await _dio.put('/auth/me', data: {'full_name': fullName});
  }

  Future<Response> getUserData() async {
    return await _dio.get('/auth/me');
  }

  // 2. اللاعب (Player)
  Future<Response> getPlayerData() async {
    return await _dio.get('/player/me');
  }

  Future<Response> getBmi() async {
    return await _dio.get('/player/bmi');
  }

  Future<Response> getStreakData() async {
    return await _dio.get('/player/streak');
  }

  Future<Response> updateHeight(double height) async {
    return await _dio.put('/player/height', data: {'height': height});
  }

  Future<Response> updateTargetWeight(double targetWeight) async {
    return await _dio.put('/player/target', data: {
      'target_weight': targetWeight,
    });
  }

  // دالة جلب بيانات الوزن
  Future<Response> getWeightData() async {
    return await _dio.get('/player/me');
  }

  // 3. المهام (Tasks)
  Future<Response> getTasks() async {
    return await _dio.get('/tasks');
  }

  Future<Response> completeTask(int taskId) async {
    return await _dio.post('/tasks/$taskId/complete');
  }

  // 4. الإحصائيات (Stats)
  Future<Response> getStats() async {
    return await _dio.get('/stats');
  }

  Future<Response> getWeeklyStats() async {
    return await _dio.get('/stats/weekly');
  }

  // 4. المهارات (Skills)
  Future<Response> getSkills() async {
    return await _dio.get('/skills/me');
  }

  Future<Response> upgradeSkill(int skillId) async {
    return await _dio.patch('/skills/me/$skillId');
  }

  // 5. الوزن (Weight)
  Future<Response> recordWeight(double weight) async {
    return await _dio.post('/weight', data: {'weight': weight});
  }

  // إضافة مهمة
  Future<Response> createTask(
    String title,
    String dimension,
    String repeatType, {
    required String difficulty,
  }) async {
    return await _dio.post('/tasks', data: {
      'title': title,
      'dimension': dimension,
      'repeat_type': repeatType,
      'difficulty': difficulty,
    });
  }

  // حذف مهمة
  Future<Response> deleteTask(int taskId) async {
    return await _dio.delete('/tasks/$taskId');
  }

  // تعديل مهمة
  Future<Response> updateTask(
    int taskId, {
    required String title,
    required String dimension,
    required String difficulty,
  }) async {
    return await _dio.put('/tasks/$taskId', data: {
      'title': title,
      'dimension': dimension,
      'difficulty': difficulty,
    });
  }
}
