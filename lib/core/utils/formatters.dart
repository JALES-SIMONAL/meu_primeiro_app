import 'package:intl/intl.dart';

String formatElapsedTime(int timestampMs) {
  final totalMilliseconds = timestampMs;
  final milliseconds = totalMilliseconds % 1000;
  final totalSeconds = totalMilliseconds ~/ 1000;
  final seconds = totalSeconds % 60;
  final totalMinutes = totalSeconds ~/ 60;
  final minutes = totalMinutes % 60;
  final hours = totalMinutes ~/ 60;

  String pad(int value, int width) => value.toString().padLeft(width, '0');
  return '${pad(hours, 2)}:${pad(minutes, 2)}:${pad(seconds, 2)}.${pad(milliseconds, 3)}';
}

String formatElapsedSeconds(int timestampMs) {
  final seconds = timestampMs / 1000.0;
  return '${seconds.toStringAsFixed(3).replaceFirst('.', ',')} s';
}

String formatReceivedAt(DateTime receivedAt) {
  final local = receivedAt.toLocal();
  final offset = local.timeZoneOffset;
  final offsetSign = offset.isNegative ? '-' : '+';
  final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
  final offsetMinutes = offset.inMinutes
      .abs()
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  final offsetText = '$offsetSign$offsetHours:$offsetMinutes';

  return '${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(local)}$offsetText';
}

String formatRelativeAge(DateTime? receivedAt) {
  if (receivedAt == null) {
    return 'Sem dados';
  }

  final elapsed = DateTime.now().difference(receivedAt);
  if (elapsed.inMilliseconds <= 0) {
    return 'agora';
  }

  if (elapsed.inSeconds < 1) {
    return '${elapsed.inMilliseconds} ms';
  }

  if (elapsed.inMinutes < 1) {
    return '${elapsed.inSeconds}s';
  }

  if (elapsed.inHours < 1) {
    return '${elapsed.inMinutes}m ${elapsed.inSeconds.remainder(60)}s';
  }

  return '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m';
}

String formatApproxBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String sanitizeFileName(String value, {String fallback = 'coleta'}) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^A-Za-z0-9_\-\.]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  return cleaned.isEmpty ? fallback : cleaned;
}
