import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/esp32_device.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::Sobre.
class SobrePage extends ConsumerWidget {
  const SobrePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final device = state.selectedDevice?.device;

    final linhas = <String, String>{
      'Equipamento': device?.displayName ?? '-',
      'Versao firmware': device?.firmwareVersion ?? '-',
      'Autor': device?.author ?? '-',
      'MAC': device?.macAddress ?? '-',
      'Modo': device?.operationMode == DeviceOperationMode.app
          ? 'Aplicativo'
          : device?.operationMode == DeviceOperationMode.hardware
          ? 'Hardware'
          : '-',
      'Canais': device?.channelCount.toString() ?? '-',
      'Bluetooth': state.bleConnected ? 'Conectado' : 'Desconectado',
      'SD': (device?.sdUsedKb != null && device?.sdTotalKb != null)
          ? '${device!.sdUsedKb}/${device.sdTotalKb} KB'
          : (device?.sdCardAvailable == false ? 'Indisponivel' : '-'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        children: [
          for (final entry in linhas.entries)
            ListTile(title: Text(entry.key), trailing: Text(entry.value)),
        ],
      ),
    );
  }
}
