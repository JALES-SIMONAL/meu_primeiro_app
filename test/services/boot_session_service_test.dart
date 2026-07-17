import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/boot_session_service.dart';

void main() {
  test('classifies reboot, overflow and out of order', () {
    final service = BootSessionService();

    expect(
      service.classify(
        lastTimestampMs: 20000,
        newTimestampMs: 1000,
        lastUptimeMs: 20000,
        newUptimeMs: 500,
      ),
      TimestampEvent.reboot,
    );

    expect(
      service.classify(
        lastTimestampMs: 20000,
        newTimestampMs: 1000,
        lastUptimeMs: 20000,
        newUptimeMs: 25000,
      ),
      TimestampEvent.millisOverflow,
    );

    expect(
      service.classify(lastTimestampMs: 20000, newTimestampMs: 19990),
      TimestampEvent.outOfOrder,
    );
  });
}
