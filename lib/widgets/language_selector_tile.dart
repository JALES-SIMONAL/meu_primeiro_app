import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import 'bordered_list_tile.dart';

/// Nome de cada idioma suportado escrito NELE MESMO (convenção padrão de
/// seletores de idioma — nunca traduzido para o idioma atualmente ativo).
const Map<String, String> _nomesIdiomas = {
  'pt': 'Português',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
};

class LanguageSelectorTile extends ConsumerWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return BorderedListTile(
      leading: const Icon(Icons.language),
      title: Text(context.tr('settings.language')),
      subtitle: Text(_nomesIdiomas[locale.languageCode] ?? locale.languageCode),
      onTap: () => _abrirSeletor(context, ref, locale),
    );
  }

  Future<void> _abrirSeletor(BuildContext context, WidgetRef ref, Locale atual) async {
    final escolhido = await showDialog<Locale>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('settings.language')),
        content: RadioGroup<Locale>(
          groupValue: atual,
          onChanged: (valor) => Navigator.of(context).pop(valor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final suportado in AppLocalizations.supportedLocales)
                RadioListTile<Locale>(
                  value: suportado,
                  title: Text(_nomesIdiomas[suportado.languageCode] ?? suportado.languageCode),
                ),
            ],
          ),
        ),
      ),
    );

    if (escolhido != null) {
      await ref.read(localeProvider.notifier).setLocale(escolhido);
    }
  }
}
