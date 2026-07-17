import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection_session.dart';
import '../../providers/app_controller.dart';
import '../../widgets/device_card.dart';
import '../../widgets/section_header.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dispositivos encontrados',
            subtitle: state.collectionSession?.stage == CollectionStage.running
                ? 'A selecao esta bloqueada durante a coleta ativa.'
                : 'Selecione apenas um dispositivo por vez.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1200
                  ? 2
                  : constraints.maxWidth >= 800
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.55,
                ),
                itemCount: state.devices.length,
                itemBuilder: (context, index) {
                  final deviceState = state.devices.values.elementAt(index);
                  final selected =
                      state.selectedDeviceId == deviceState.device.deviceId;
                  final locked =
                      state.collectionSession?.stage == CollectionStage.running;
                  return DeviceCard(
                    deviceState: deviceState,
                    selected: selected,
                    selectionLocked: locked,
                    onSelect: () =>
                        controller.selectDevice(deviceState.device.deviceId),
                    onToggleOnline: (online) => controller.setDeviceOnline(
                      deviceState.device.deviceId,
                      online,
                    ),
                    onReboot: () => controller.simulateDeviceReboot(
                      deviceState.device.deviceId,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
