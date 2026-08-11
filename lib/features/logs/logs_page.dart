import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/app_log_entry.dart';
import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          TextButton(
            onPressed: ref.read(appControllerProvider.notifier).clearLogs,
            child: const Text('Limpar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Logs',
              subtitle: 'Eventos do parser, MQTT, coleta e demo.',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final entry in state.logs.reversed)
                      ListTile(
                        leading: Icon(
                          _iconFor(entry.level),
                          color: _colorFor(entry.level),
                        ),
                        title: Text(entry.message),
                        subtitle: Text(formatReceivedAt(entry.timestamp)),
                      ),
                    if (state.logs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Nenhum log ainda.'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.info => Icons.info_outline,
      AppLogLevel.success => Icons.check_circle_outline,
      AppLogLevel.warning => Icons.warning_amber_outlined,
      AppLogLevel.error => Icons.error_outline,
    };
  }

  Color _colorFor(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.info => const Color(0xFF04BBD3),
      AppLogLevel.success => const Color(0xFF2E7D32),
      AppLogLevel.warning => const Color(0xFFF9A825),
      AppLogLevel.error => const Color(0xFFC62828),
    };
  }
}
