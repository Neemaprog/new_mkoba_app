import 'package:flutter_test/flutter_test.dart';
import 'package:mkoba_system/main.dart';

void main() {
  testWidgets('Mkoba app test', (WidgetTester tester) async {
    await tester.pumpWidget(const MkobaApp());
  });
}
