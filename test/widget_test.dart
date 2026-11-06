import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowdev_app/main.dart';

void main() {
  testWidgets('shows the splash screen when no access token is stored',
      (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const ShadowDevApp());
    await tester.pumpAndSettle();

    expect(find.text('لقد تم اختيارك كلاعب'), findsOneWidget);
    expect(find.text('ابدأ النهوض'), findsOneWidget);
  });
}
