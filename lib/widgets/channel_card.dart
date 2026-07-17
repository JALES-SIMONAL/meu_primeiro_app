import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/esp32_device_state.dart';
import '../models/sensor_state.dart';

class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.deviceOnline,
  });

  final ChannelState channel;
  final bool deviceOnline;

  @override
  Widget build(BuildContext context) {
    final state = channel.state ?? SensorState.unknown;
    final colors = _cardColors(state, deviceOnline);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [colors.background, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sensor ${channel.sensor}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _Led(state: state, online: deviceOnline),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              state.shortCode,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: colors.foreground),
            ),
            Text(
              state.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.foreground),
            ),
            const SizedBox(height: 12),
            _Metric(
              label: 'timestampMs',
              value: channel.timestampMs?.toString() ?? '---',
            ),
            _Metric(
              label: 'tempo relativo',
              value: channel.timestampMs == null
                  ? '---'
                  : formatElapsedTime(channel.timestampMs!),
            ),
            _Metric(
              label: 'recebido',
              value: channel.receivedAt == null
                  ? '---'
                  : formatReceivedAt(channel.receivedAt!),
            ),
            _Metric(
              label: 'tempo sem atualizar',
              value: formatRelativeAge(channel.receivedAt),
            ),
            _Metric(label: 'mensagens', value: channel.messageCount.toString()),
            _Metric(label: 'mudancas', value: channel.changeCount.toString()),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Led extends StatelessWidget {
  const _Led({required this.state, required this.online});

  final SensorState state;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      SensorState.high => const Color(0xFF2E7D32),
      SensorState.low => const Color(0xFFC62828),
      SensorState.unknown =>
        online ? const Color(0xFF7A7A7A) : const Color(0xFF4E5459),
    };

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _CardColors {
  final Color background;
  final Color foreground;

  const _CardColors({required this.background, required this.foreground});
}

_CardColors _cardColors(SensorState state, bool deviceOnline) {
  if (!deviceOnline) {
    return const _CardColors(
      background: Color(0xFFE8ECEF),
      foreground: Color(0xFF4E5459),
    );
  }

  switch (state) {
    case SensorState.high:
      return const _CardColors(
        background: Color(0xFFE8F5E9),
        foreground: Color(0xFF2E7D32),
      );
    case SensorState.low:
      return const _CardColors(
        background: Color(0xFFFFEBEE),
        foreground: Color(0xFFC62828),
      );
    case SensorState.unknown:
      return const _CardColors(
        background: Color(0xFFF1F3F5),
        foreground: Color(0xFF7A7A7A),
      );
  }
}
