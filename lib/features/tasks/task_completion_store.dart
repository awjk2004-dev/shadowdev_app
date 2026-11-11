import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TaskCompletionStore {
  TaskCompletionStore({
    required this.owner,
    FlutterSecureStorage? storage,
    DateTime Function()? clock,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _clock = clock ?? DateTime.now;

  final String owner;
  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  String get _key => 'completed_tasks_${Uri.encodeComponent(owner)}';

  Future<Set<int>> loadToday() async {
    final value = await _storage.read(key: _key);
    if (value == null) return {};

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored task completion data is invalid');
    }
    if (decoded['date'] != _today) return {};
    if (decoded['ids'] is! List) {
      throw const FormatException('Stored task completion IDs are invalid');
    }

    final ids = <int>{};
    for (final value in decoded['ids'] as List) {
      final id = int.tryParse(value.toString());
      if (id == null) {
        throw const FormatException('Stored task completion ID is invalid');
      }
      ids.add(id);
    }
    return ids;
  }

  Future<void> saveToday(Set<int> taskIds) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'date': _today,
        'ids': taskIds.toList()..sort(),
      }),
    );
  }

  String get _today {
    final now = _clock();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
