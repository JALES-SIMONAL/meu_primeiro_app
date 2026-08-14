import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Carrega e resolve as traduções do app a partir de `assets/l10n/<idioma>.json`
/// — chaves em dot-notation (ex.: "common.save") mapeadas direto para o
/// texto, sem aninhamento, para manter o loader simples. Português (pt) é
/// sempre o fallback: se uma chave faltar no idioma atual, ou o arquivo do
/// idioma não existir, cai para pt em vez de mostrar a chave crua.
class AppLocalizations {
  AppLocalizations(this.locale, this._strings, this._fallback);

  final Locale locale;
  final Map<String, String> _strings;
  final Map<String, String>? _fallback;

  static const List<Locale> supportedLocales = [
    Locale('pt'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  static const Locale fallbackLocale = Locale('pt');

  static Locale resolveSupported(Locale locale) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return fallbackLocale;
  }

  static Future<Map<String, String>> _loadRaw(String languageCode) async {
    final jsonStr = await rootBundle.loadString('assets/l10n/$languageCode.json');
    final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<AppLocalizations> load(Locale requested) async {
    final resolved = resolveSupported(requested);
    final fallback = resolved == fallbackLocale ? null : await _loadRaw(fallbackLocale.languageCode);
    final strings = await _loadRaw(resolved.languageCode);
    return AppLocalizations(resolved, strings, fallback);
  }

  /// Busca [key] no idioma atual (com fallback para pt); {param} dentro do
  /// texto é substituído pelo valor correspondente em [params]. Se a chave
  /// não existir em nenhum dos dois, retorna a própria chave — mais fácil de
  /// notar um texto esquecido do que um app quebrado silenciosamente.
  String tr(String key, {Map<String, String>? params}) {
    var value = _strings[key] ?? _fallback?[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }
}

/// Disponibiliza o [AppLocalizations] já carregado para toda a árvore de
/// widgets — atualizado sempre que o idioma muda (ver LocaleController).
class AppLocalizationsScope extends InheritedWidget {
  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  final AppLocalizations localizations;

  static AppLocalizations of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    assert(scope != null, 'AppLocalizationsScope nao encontrado no contexto.');
    return scope!.localizations;
  }

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) =>
      oldWidget.localizations != localizations;
}

/// Açúcar sintático: `context.tr('common.save')` em vez de
/// `AppLocalizationsScope.of(context).tr('common.save')`.
extension AppLocalizationsX on BuildContext {
  String tr(String key, {Map<String, String>? params}) =>
      AppLocalizationsScope.of(this).tr(key, params: params);
}
