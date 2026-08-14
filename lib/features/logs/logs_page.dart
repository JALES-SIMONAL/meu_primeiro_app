import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_log_entry.dart';
import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(appControllerProvider.select((s) => s.logs));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('logs.title')),
        actions: [
          TextButton(
            onPressed: ref.read(appControllerProvider.notifier).clearLogs,
            child: Text(context.tr('logs.clear')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: context.tr('logs.sectionTitle'),
              subtitle: context.tr('logs.sectionSubtitle'),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final entry in logs.reversed)
                      ListTile(
                        leading: Icon(
                          _iconFor(entry.level),
                          color: _colorFor(context, entry.level),
                        ),
                        title: Text(entry.message),
                        subtitle: Text(formatReceivedAt(entry.timestamp)),
                      ),
                    if (logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(context.tr('logs.empty')),
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

  Color _colorFor(BuildContext context, AppLogLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (level) {
      AppLogLevel.info => colorScheme.primary,
      AppLogLevel.success => AppColors.levelHigh,
      AppLogLevel.warning => colorScheme.tertiary,
      AppLogLevel.error => colorScheme.error,
    };
  }
}
