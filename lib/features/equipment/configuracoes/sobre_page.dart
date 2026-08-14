import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/esp32_device.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::Sobre.
class SobrePage extends ConsumerWidget {
  const SobrePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (device, bleConnected) = ref.watch(
      appControllerProvider.select((s) => (s.selectedDevice?.device, s.bleConnected)),
    );
    final na = context.tr('common.notAvailable');

    final linhas = <String, String>{
      context.tr('equipmentAbout.equipment'): device?.displayName ?? na,
      context.tr('equipmentAbout.firmwareVersion'): device?.firmwareVersion ?? na,
      context.tr('equipmentAbout.author'): device?.author ?? na,
      context.tr('equipmentAbout.mac'): device?.macAddress ?? na,
      context.tr('equipmentAbout.mode'): device?.operationMode == DeviceOperationMode.app
          ? context.tr('equipmentAbout.modeApp')
          : device?.operationMode == DeviceOperationMode.hardware
          ? context.tr('equipmentAbout.modeHardware')
          : na,
      context.tr('equipmentAbout.channels'): device?.channelCount.toString() ?? na,
      context.tr('equipmentAbout.bluetooth'): bleConnected
          ? context.tr('common.connected')
          : context.tr('common.disconnected'),
      context.tr('equipmentAbout.sd'): (device?.sdUsedKb != null && device?.sdTotalKb != null)
          ? '${device!.sdUsedKb}/${device.sdTotalKb} KB'
          : (device?.sdCardAvailable == false ? context.tr('equipmentAbout.sdUnavailable') : na),
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('equipmentAbout.title'))),
      body: ListView(
        children: [
          for (final entry in linhas.entries)
            ListTile(title: Text(entry.key), trailing: Text(entry.value)),
        ],
      ),
    );
  }
}
