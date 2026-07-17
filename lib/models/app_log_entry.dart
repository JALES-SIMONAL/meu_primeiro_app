enum AppLogLevel { info, success, warning, error }

class AppLogEntry {
  final DateTime timestamp;
  final AppLogLevel level;
  final String message;

  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}
