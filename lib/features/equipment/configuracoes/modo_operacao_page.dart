import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/esp32_device.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ModoOperacao.
class ModoOperacaoPage extends ConsumerWidget {
  const ModoOperacaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final modo = state.selectedDevice?.device.operationMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Modo de operacao')),
      body: RadioGroup<DeviceOperationMode>(
        groupValue: modo,
        onChanged: (value) =>
            controller.setOperationMode(value == DeviceOperationMode.app),
        child: ListView(
          children: const [
            RadioListTile<DeviceOperationMode>(
              title: Text('Controle pelo hardware'),
              subtitle: Text('Encoder e tecla do equipamento'),
              value: DeviceOperationMode.hardware,
            ),
            RadioListTile<DeviceOperationMode>(
              title: Text('Controle pelo aplicativo'),
              subtitle: Text('Este app'),
              value: DeviceOperationMode.app,
            ),
          ],
        ),
      ),
    );
  }
}
