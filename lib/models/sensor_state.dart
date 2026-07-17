/// Estado lógico de um canal do ESP32.
enum SensorState {
  high,
  low,
  unknown;

  String get shortCode {
    switch (this) {
      case SensorState.high:
        return 'H';
      case SensorState.low:
        return 'L';
      case SensorState.unknown:
        return '?';
    }
  }

  String get description {
    switch (this) {
      case SensorState.high:
        return 'HIGH';
      case SensorState.low:
        return 'LOW';
      case SensorState.unknown:
        return 'UNKNOWN';
    }
  }

  static SensorState? tryParse(Object? raw) {
    if (raw == null) return null;

    if (raw is bool) {
      return raw ? SensorState.high : SensorState.low;
    }

    if (raw is num) {
      if (raw == 1) return SensorState.high;
      if (raw == 0) return SensorState.low;
      return null;
    }

    if (raw is String) {
      final value = raw.trim().toUpperCase();
      switch (value) {
        case 'H':
        case 'HIGH':
        case '1':
        case 'TRUE':
          return SensorState.high;
        case 'L':
        case 'LOW':
        case '0':
        case 'FALSE':
          return SensorState.low;
        default:
          return null;
      }
    }

    return null;
  }
}
