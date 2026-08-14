import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/esp32_device.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ModoOperacao.
class ModoOperacaoPage extends ConsumerWidget {
  const ModoOperacaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modo = ref.watch(
      appControllerProvider.select((s) => s.selectedDevice?.device.operationMode),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('operationMode.title'))),
      body: RadioGroup<DeviceOperationMode>(
        groupValue: modo,
        onChanged: (value) =>
            controller.setOperationMode(value == DeviceOperationMode.app),
        child: ListView(
          children: [
            RadioListTile<DeviceOperationMode>(
              title: Text(context.tr('operationMode.hardware')),
              subtitle: Text(context.tr('operationMode.hardwareSubtitle')),
              value: DeviceOperationMode.hardware,
            ),
            RadioListTile<DeviceOperationMode>(
              title: Text(context.tr('operationMode.app')),
              subtitle: Text(context.tr('operationMode.appSubtitle')),
              value: DeviceOperationMode.app,
            ),
          ],
        ),
      ),
    );
  }
}
