import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../providers/app_controller.dart';
import '../../services/bluetooth_service.dart';
import '../../widgets/section_header.dart';
import '../../widgets/zebra_row.dart';

class BluetoothPage extends ConsumerWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      appControllerProvider.select(
        (s) => (
          bleConnected: s.bleConnected,
          bleScanning: s.bleScanning,
          bleScanResults: s.bleScanResults,
          selectedDeviceId: s.selectedDeviceId,
        ),
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('bluetooth.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: context.tr('bluetooth.sectionTitle')),
            const SizedBox(height: 12),
            StreamBuilder<bool>(
              stream: controller.bleAdapterOn,
              builder: (context, snapshot) {
                if (snapshot.data == false) {
                  return Card(
                    color: colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.bluetooth_disabled),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(context.tr('bluetooth.adapterOff')),
                          ),
                          FilledButton.icon(
                            onPressed: controller.turnOnBluetoothAdapter,
                            icon: const Icon(Icons.bluetooth),
                            label: Text(context.tr('common.activate')),
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
                  label: Text(
                    state.bleScanning
                        ? context.tr('bluetooth.scanning')
                        : context.tr('common.scan'),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: state.bleConnected
                      ? controller.disconnectBluetooth
                      : null,
                  icon: const Icon(Icons.bluetooth_disabled),
                  label: Text(context.tr('common.disconnect')),
                ),
                Chip(
                  label: Text(
                    state.bleConnected
                        ? context.tr('common.connected')
                        : context.tr('common.disconnected'),
                  ),
                  backgroundColor: state.bleConnected
                      ? colorScheme.primaryContainer
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
                      context.tr('bluetooth.foundDevices'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (state.bleScanResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          state.bleScanning
                              ? context.tr('bluetooth.scanningHint')
                              : context.tr('bluetooth.noDevicesHint'),
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
          Icon(Icons.bluetooth, color: isKnown ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty ? device.name : context.tr('bluetooth.noName'),
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
              ? Chip(label: Text(context.tr('common.connected')))
              : FilledButton(
                  onPressed: onConnect,
                  child: Text(context.tr('bluetooth.connectButton')),
                ),
        ],
      ),
    );
  }
}
