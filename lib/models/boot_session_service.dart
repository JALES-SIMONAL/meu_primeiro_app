enum TimestampEvent { normal, reboot, millisOverflow, outOfOrder }

class BootSessionService {
  static const int significantDropThresholdMs = 5000;
  static const int nearZeroThresholdMs = 5000;

  TimestampEvent classify({
    required int? lastTimestampMs,
    required int newTimestampMs,
    int? lastUptimeMs,
    int? newUptimeMs,
  }) {
    if (lastTimestampMs == null) return TimestampEvent.normal;

    if (newTimestampMs >= lastTimestampMs) {
      return TimestampEvent.normal;
    }

    final drop = lastTimestampMs - newTimestampMs;
    if (drop < significantDropThresholdMs) {
      return TimestampEvent.outOfOrder;
    }

    if (newUptimeMs != null && lastUptimeMs != null) {
      final uptimeAlsoDropped =
          newUptimeMs < nearZeroThresholdMs && newUptimeMs < lastUptimeMs;
      if (!uptimeAlsoDropped) {
        return TimestampEvent.millisOverflow;
      }
    }

    return TimestampEvent.reboot;
  }
}
