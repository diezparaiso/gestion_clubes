// MODIFICADO POR GPT-5.6 LUNA (2026-09-30): base de internacionalización ES/EN/IT/PT.
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
    Locale('it'),
    Locale('pt'),
  ];

  static const _strings = <String, Map<String, String>>{
    'language': {'es': 'Idioma', 'en': 'Language', 'it': 'Lingua', 'pt': 'Idioma'},
    'spanish': {'es': 'Español', 'en': 'Spanish', 'it': 'Spagnolo', 'pt': 'Espanhol'},
    'english': {'es': 'Inglés', 'en': 'English', 'it': 'Inglese', 'pt': 'Inglês'},
    'italian': {'es': 'Italiano', 'en': 'Italian', 'it': 'Italiano', 'pt': 'Italiano'},
    'portuguese': {'es': 'Portugués', 'en': 'Portuguese', 'it': 'Portoghese', 'pt': 'Português'},
    'dashboard': {'es': 'Panel de control', 'en': 'Dashboard', 'it': 'Dashboard', 'pt': 'Painel'},
    'members': {'es': 'Socios', 'en': 'Members', 'it': 'Soci', 'pt': 'Sócios'},
    'teams': {'es': 'Equipos', 'en': 'Teams', 'it': 'Squadre', 'pt': 'Equipas'},
    'finance': {'es': 'Finanzas', 'en': 'Finance', 'it': 'Finanze', 'pt': 'Finanças'},
    'events': {'es': 'Eventos', 'en': 'Events', 'it': 'Eventi', 'pt': 'Eventos'},
    'news': {'es': 'Noticias', 'en': 'News', 'it': 'Notizie', 'pt': 'Notícias'},
    'notifications': {'es': 'Notificaciones', 'en': 'Notifications', 'it': 'Notifiche', 'pt': 'Notificações'},
    'settings': {'es': 'Configuración', 'en': 'Settings', 'it': 'Impostazioni', 'pt': 'Definições'},
    'profile': {'es': 'Perfil', 'en': 'Profile', 'it': 'Profilo', 'pt': 'Perfil'},
    'save': {'es': 'Guardar', 'en': 'Save', 'it': 'Salva', 'pt': 'Guardar'},
    'cancel': {'es': 'Cancelar', 'en': 'Cancel', 'it': 'Annulla', 'pt': 'Cancelar'},
    'search': {'es': 'Buscar', 'en': 'Search', 'it': 'Cerca', 'pt': 'Pesquisar'},
    'loading': {'es': 'Cargando…', 'en': 'Loading…', 'it': 'Caricamento…', 'pt': 'A carregar…'},
    'error': {'es': 'Se ha producido un error', 'en': 'Something went wrong', 'it': 'Si è verificato un errore', 'pt': 'Ocorreu um erro'},
    'logout': {'es': 'Cerrar sesión', 'en': 'Log out', 'it': 'Esci', 'pt': 'Terminar sessão'},
  };

  String t(String key) =>
      _strings[key]?[locale.languageCode] ?? _strings[key]?['es'] ?? key;

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return value ?? const AppLocalizations(Locale('es'));
  }

  static const delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((item) => item.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
