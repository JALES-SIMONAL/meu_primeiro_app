import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/zebra_row.dart';

class BluetoothPage extends ConsumerWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Conexao Bluetooth'),
            const SizedBox(height: 12),
            StreamBuilder<bool>(
              stream: controller.bleAdapterOn,
              builder: (context, snapshot) {
                if (snapshot.data == false) {
                  return Card(
                    color: const Color(0xFFFFF3E0),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.bluetooth_disabled),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('O Bluetooth do aparelho esta desligado.'),
                          ),
                          FilledButton(
                            onPressed: controller.turnOnBluetoothAdapter,
                            child: const Text('Ativar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: state.bleScanning ? null : controller.startBleScan,
                  icon: state.bleScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(state.bleScanning ? 'Escaneando...' : 'Escanear'),
                ),
                FilledButton.tonal(
                  onPressed: state.bleConnected
                      ? controller.disconnectBluetooth
                      : null,
                  child: const Text('Desconectar'),
                ),
                Chip(
                  label: Text(
                    state.bleConnected ? 'Conectado' : 'Desconectado',
                  ),
                  backgroundColor: state.bleConnected
                      ? const Color(0xFFE8F5E9)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispositivos encontrados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (state.bleScanResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          state.bleScanning
                              ? 'Procurando dispositivos por perto...'
                              : 'Nenhum dispositivo encontrado ainda. Toque em "Escanear".',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          children: [
                            for (final (index, device)
                                in state.bleScanResults.indexed)
                              _DeviceTile(
                                index: index,
                                device: device,
                                connected:
                                    state.bleConnected &&
                                    state.selectedDeviceId == device.id,
                                onConnect: () =>
                                    controller.connectToDevice(device.id),
                              ),
                          ],
                        ),
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
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.index,
    required this.device,
    required this.connected,
    required this.onConnect,
  });

  final int index;
  final BleDeviceInfo device;
  final bool connected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final isKnown = device.isKnownDevice;
    return ZebraRow(
      index: index,
      selected: connected,
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: isKnown ? const Color(0xFF04BBD3) : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty ? device.name : '(sem nome)',
                  style: TextStyle(fontWeight: isKnown ? FontWeight.w700 : null),
                ),
                Text(
                  '${device.id} • RSSI ${device.rssi} dBm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          connected
              ? const Chip(label: Text('Conectado'))
              : FilledButton(
                  onPressed: onConnect,
                  child: const Text('Conectar'),
                ),
        ],
      ),
    );
  }
}
