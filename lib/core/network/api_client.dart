import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // نستخدم localhost لأننا فعلنا adb reverse
  static const String baseUrl = 'http://localhost:8000/api/v1';
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
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // 1. المصادقة (Auth)
  Future<Response> login(String username, String password) async {
    final formData = FormData.fromMap({
      'username': username,
      'password': password,
    });
    return await _dio.post('/auth/login', data: formData);
  }

  Future<Response> register(String username, String fullName, String password) async {
    return await _dio.post('/auth/register', data: {
      'username': username,
      'full_name': fullName,
      'password': password,
    });
  }

  Future<Response> updateProfile(String fullName) async {
    return await _dio.put('/auth/me', data: {'full_name': fullName});
  }

  // 2. اللاعب (Player)
  Future<Response> getPlayerData() async {
    return await _dio.get('/player/me');
  }

  Future<Response> getBmi() async {
    return await _dio.get('/player/bmi');
  }

  Future<Response> updateHeight(double height) async {
    return await _dio.put('/player/height', data: {'height': height});
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
}