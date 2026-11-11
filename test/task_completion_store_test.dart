import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowdev/features/tasks/task_completion_store.dart';

void main() {
  group('TaskCompletionStore', () {
    test('keeps completed task IDs across store instances on the same day',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final today = DateTime(2026, 11, 11);
      final firstStore = TaskCompletionStore(
        owner: 'player',
        clock: () => today,
      );
      final reopenedStore = TaskCompletionStore(
        owner: 'player',
        clock: () => today,
      );

      await firstStore.saveToday({2, 4});

      expect(await reopenedStore.loadToday(), {2, 4});
    });

    test('isolates completions by user', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = TaskCompletionStore(
        owner: 'player-one',
        clock: () => DateTime(2026, 11, 11),
      );
      final otherUserStore = TaskCompletionStore(
        owner: 'player-two',
        clock: () => DateTime(2026, 11, 11),
      );

      await store.saveToday({2});

      expect(await otherUserStore.loadToday(), isEmpty);
    });

    test('resets daily completions on a new day', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = TaskCompletionStore(
        owner: 'player',
        clock: () => DateTime(2026, 11, 11),
      );
      final nextDayStore = TaskCompletionStore(
        owner: 'player',
        clock: () => DateTime(2026, 11, 12),
      );

      await store.saveToday({2});

      expect(await nextDayStore.loadToday(), isEmpty);
    });
  });
}
