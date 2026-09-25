import 'package:flutter_test/flutter_test.dart';
import 'package:my_farm_accounts/main.dart';

void main() {
  testWidgets('app starts with dashboard', (tester) async {
    await tester.pumpWidget(const MyFarmAccountsApp());
    await tester.pumpAndSettle();
    expect(find.text('حسابات مزرعتي'), findsWidgets);
    expect(find.text('لوحة التحكم'), findsOneWidget);
  });
}
