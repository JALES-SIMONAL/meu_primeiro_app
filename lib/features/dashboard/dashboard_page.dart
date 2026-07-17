import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/app_state.dart';
import '../../providers/app_controller.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/monkey_tech_logo.dart';
import '../../widgets/section_header.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final selected = state.selectedDevice;
    final device = selected?.device;
    final channels = selected?.channels.values.toList() ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(state: state),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Canais do dispositivo selecionado',
            subtitle: device == null
                ? 'Nenhum dispositivo selecionado.'
                : device.displayName,
          ),
          const SizedBox(height: 12),
          if (selected == null)
            const _EmptyState(
              message:
                  'Selecione um dispositivo na aba Dispositivos para ver os 6 canais.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 1.6 : 1.45,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    return ChannelCard(
                      channel: channels[index],
                      deviceOnline: device?.isOnline ?? false,
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Resumo rapido',
            subtitle: 'Contagem de estados e mensagens do dispositivo ativo.',
          ),
          const SizedBox(height: 12),
          if (selected != null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryTile(
                  label: 'HIGH',
                  value: selected.highCount.toString(),
                  color: const Color(0xFF2E7D32),
                ),
                _SummaryTile(
                  label: 'LOW',
                  value: selected.lowCount.toString(),
                  color: const Color(0xFFC62828),
                ),
                _SummaryTile(
                  label: 'Sem dados',
                  value: selected.noDataCount.toString(),
                  color: const Color(0xFF7A7A7A),
                ),
                _SummaryTile(
                  label: 'Mensagens',
                  value: selected.totalMessages.toString(),
                  color: const Color(0xFF04BBD3),
                ),
                _SummaryTile(
                  label: 'Reboots',
                  value: selected.rebootCount.toString(),
                  color: const Color(0xFFF9A825),
                ),
                _SummaryTile(
                  label: 'Ultima comunicacao',
                  value: formatRelativeAge(device?.lastSeen),
                  color: const Color(0xFF000000),
                ),
              ],
            )
          else
            const _EmptyState(message: 'Nao ha dispositivo selecionado.'),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedDevice;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF04BBD3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const MonkeyTechLogo(size: 104),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monkey Tech Data Logger',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  selected == null
                      ? 'Selecione um ESP32 para acompanhar os 6 canais e iniciar a coleta.'
                      : 'Dispositivo: ${selected.device.displayName} • ${selected.device.deviceId}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip(
                      label: state.demoMode ? 'Demo ativa' : 'Demo inativa',
                    ),
                    _HeaderChip(
                      label: state.mqttConnected
                          ? 'MQTT conectado'
                          : 'MQTT offline',
                    ),
                    _HeaderChip(
                      label:
                          state.collectionSession?.stage.name ?? 'Sem coleta',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Text(message),
    );
  }
}
