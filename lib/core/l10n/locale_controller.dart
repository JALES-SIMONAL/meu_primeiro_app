import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

const _prefsKeyLocale = 'app_locale';

/// Idioma selecionado pelo usuário — português é o padrão/inicial
/// (AppLocalizations.fallbackLocale), persistido em SharedPreferences para
/// sobreviver a reinícios do app.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    // Estado inicial síncrono (pt); _carregarPersistido() corrige para o
    // idioma salvo (se houver) assim que o SharedPreferences responder.
    _carregarPersistido();
    return AppLocalizations.fallbackLocale;
  }

  Future<void> _carregarPersistido() async {
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(_prefsKeyLocale);
    if (salvo == null) return;
    state = AppLocalizations.resolveSupported(Locale(salvo));
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = AppLocalizations.resolveSupported(locale);
    state = resolved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLocale, resolved.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Traduções carregadas para o idioma atual (ver localeProvider) — recarrega
/// automaticamente sempre que o idioma muda.
final appLocalizationsProvider = FutureProvider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations.load(locale);
});
