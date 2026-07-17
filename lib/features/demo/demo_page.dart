import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';

class DemoPage extends ConsumerWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final demoDevices = state.devices.values
        .where((device) => device.device.deviceId.startsWith('esp32_demo_'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Modo demonstracao',
            subtitle: 'Funciona sem ESP32 e sem broker MQTT.',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: state.demoMode,
            onChanged: controller.toggleDemoMode,
            title: const Text('Ativar demo mode'),
            subtitle: const Text(
              'Gera leituras para os tres dispositivos virtuais.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final device in demoDevices)
                SizedBox(
                  width: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.device.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(device.device.deviceId),
                          const SizedBox(height: 10),
                          Text('Boot ${device.device.bootSession}'),
                          Text(device.device.isOnline ? 'Online' : 'Offline'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => controller.setDeviceOnline(
                                  device.device.deviceId,
                                  !device.device.isOnline,
                                ),
                                child: Text(
                                  device.device.isOnline ? 'Offline' : 'Online',
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: () =>
                                    controller.simulateDeviceReboot(
                                      device.device.deviceId,
                                    ),
                                child: const Text('Reboot'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
