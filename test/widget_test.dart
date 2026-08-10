import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_primeiro_app/app/monkey_tech_app.dart';

void main() {
  testWidgets('renders the app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MonkeyTechApp()));
    await tester.pumpAndSettle();

    expect(find.text('Experimentos'), findsWidgets);
    expect(find.text('Analise de Dados'), findsWidgets);
    expect(find.text('Configuracoes'), findsWidgets);
  });
}
