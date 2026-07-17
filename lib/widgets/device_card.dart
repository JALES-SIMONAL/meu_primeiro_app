import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/esp32_device_state.dart';
import 'monkey_tech_logo.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.deviceState,
    required this.selected,
    required this.selectionLocked,
    required this.onSelect,
    required this.onToggleOnline,
    required this.onReboot,
  });

  final Esp32DeviceState deviceState;
  final bool selected;
  final bool selectionLocked;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggleOnline;
  final VoidCallback onReboot;

  @override
  Widget build(BuildContext context) {
    final device = deviceState.device;
    final borderColor = selected
        ? Theme.of(context).colorScheme.secondary
        : const Color(0xFFE0E5E8);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: selected ? 1.8 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MonkeyTechLogo(size: 56, showText: false),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        device.deviceId,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StateChip(online: device.isOnline),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'MAC', value: device.macAddress ?? '---'),
                _InfoChip(label: 'FW', value: device.firmwareVersion ?? '---'),
                _InfoChip(label: 'Boot', value: device.bootSession.toString()),
                _InfoChip(
                  label: 'Ultima',
                  value: formatRelativeAge(device.lastSeen),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: selectionLocked && !selected ? null : onSelect,
                    child: Text(selected ? 'Selecionado' : 'Selecionar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => onToggleOnline(!device.isOnline),
                  icon: Icon(device.isOnline ? Icons.wifi_off : Icons.wifi),
                  tooltip: device.isOnline
                      ? 'Definir offline'
                      : 'Definir online',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: onReboot,
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Simular reboot',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF2E7D32) : const Color(0xFF6C757D);
    return Chip(
      label: Text(online ? 'Online' : 'Offline'),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.info_outline, size: 16),
    );
  }
}
