import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/shell/app_shell.dart';

class MonkeyTechApp extends ConsumerWidget {
  const MonkeyTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocalizations = ref.watch(appLocalizationsProvider);

    // AppLocalizationsScope precisa envolver o MaterialApp inteiro (não só
    // "home"): dialogos/rotas empurrados pelo Navigator interno do
    // MaterialApp também precisam encontrar o InheritedWidget na árvore.
    return asyncLocalizations.when(
      data: (localizations) => AppLocalizationsScope(
        localizations: localizations,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Monkey Tech Data Logger',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          locale: localizations.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Respeita o tamanho de fonte do sistema (acessibilidade), mas
            // com um teto/piso — sem isto, um usuário com fonte do sistema
            // muito grande (ex.: 200%) quebraria layouts com largura fixa
            // (ListTile, Chip). O intervalo [0.85, 1.6] ainda cobre a maior
            // parte dos ajustes reais de acessibilidade sem estourar o
            // layout.
            return MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.6,
              child: child!,
            );
          },
          home: const AppShell(),
        ),
      ),
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text('Erro ao carregar idioma: $error'))),
      ),
    );
  }
}
