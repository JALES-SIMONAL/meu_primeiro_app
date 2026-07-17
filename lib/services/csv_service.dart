import 'dart:convert';

import '../core/utils/formatters.dart';
import '../models/sensor_record.dart';

class CsvService {
  String buildCsv(List<SensorRecord> records, {String delimiter = ';'}) {
    final buffer = StringBuffer();
    buffer.writeln(SensorRecord.csvHeader);
    for (final record in records) {
      buffer.writeln(record.toCsvRow(delimiter: delimiter));
    }
    return buffer.toString();
  }

  String suggestFileName(String deviceId, {String label = 'ensaio_01'}) {
    return '${sanitizeFileName(deviceId)}_${sanitizeFileName(label)}.csv';
  }

  String escapeForDownload(String content) => utf8.decode(utf8.encode(content));
}
