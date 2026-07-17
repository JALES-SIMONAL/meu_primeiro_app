import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_primeiro_app/app/monkey_tech_app.dart';

void main() {
  testWidgets('renders the app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MonkeyTechApp()));
    await tester.pumpAndSettle();

    expect(find.text('Monkey Tech Data Logger'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Dispositivos'), findsWidgets);
  });
}
