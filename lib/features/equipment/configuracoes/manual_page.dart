import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::Manual (lá é um QR Code; aqui basta
/// mostrar a URL, recebida do equipamento na mensagem "info").
class ManualPage extends ConsumerWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(
      appControllerProvider.select((s) => s.selectedDevice?.device.manualUrl),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('manual.title'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('manual.urlLabel')),
            const SizedBox(height: 12),
            SelectableText(
              url?.isNotEmpty == true ? url! : context.tr('manual.notAvailable'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
