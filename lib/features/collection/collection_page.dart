import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/collection_session.dart';
import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  final _fileNameController = TextEditingController();
  String _delimiter = ';';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final controller = ref.read(appControllerProvider.notifier);
    _fileNameController.text = controller.suggestCollectionFileName();
    _initialized = true;
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final selected = state.selectedDevice;
    final session = state.collectionSession;
    final records = selected == null
        ? const []
        : state.recordsFor(selected.device.deviceId).reversed.take(12).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Coleta de dados',
            subtitle:
                'Inicie, pause, retome e finalize a coleta do dispositivo selecionado.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dispositivo selecionado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected?.device.displayName ??
                        'Nenhum dispositivo selecionado',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fileNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do arquivo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          initialValue: _delimiter,
                          decoration: const InputDecoration(
                            labelText: 'Separador',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ';',
                              child: Text('Ponto e vírgula'),
                            ),
                            DropdownMenuItem(
                              value: ',',
                              child: Text('Virgula'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _delimiter = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () {
                          controller.startCollection(
                            fileName: _fileNameController.text,
                            delimiter: _delimiter,
                          );
                        },
                        child: const Text('Iniciar'),
                      ),
                      FilledButton.tonal(
                        onPressed: session?.stage == CollectionStage.running
                            ? controller.pauseCollection
                            : null,
                        child: const Text('Pausar'),
                      ),
                      FilledButton.tonal(
                        onPressed: session?.stage == CollectionStage.paused
                            ? controller.resumeCollection
                            : null,
                        child: const Text('Continuar'),
                      ),
                      FilledButton.tonal(
                        onPressed: session == null
                            ? null
                            : controller.finishCollection,
                        child: const Text('Finalizar'),
                      ),
                      FilledButton.tonal(
                        onPressed: session == null
                            ? null
                            : controller.cancelCollection,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                title: 'Status',
                value: session?.stage.name ?? 'idle',
              ),
              _MetricTile(
                title: 'Registros',
                value: session?.recordCount.toString() ?? '0',
              ),
              _MetricTile(
                title: 'Duracao',
                value: session == null
                    ? '00:00:00.000'
                    : formatElapsedTime(
                        DateTime.now()
                            .difference(session.startedAt)
                            .inMilliseconds,
                      ),
              ),
              _MetricTile(
                title: 'Ultima mensagem',
                value: session?.lastRecord == null
                    ? '---'
                    : '${session!.lastRecord!.sensor} ${session.lastRecord!.state.shortCode}',
              ),
              _MetricTile(
                title: 'Tamanho aprox.',
                value: formatApproxBytes(session?.sizeEstimateBytes ?? 0),
              ),
              _MetricTile(
                title: 'Arquivo',
                value:
                    session?.fileName ?? controller.suggestCollectionFileName(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Registros recentes',
            subtitle: 'Ultimos itens recebidos para o dispositivo ativo.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: records.isEmpty
                  ? const Text('Sem registros ainda.')
                  : Column(
                      children: [
                        for (final record in records)
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              child: Text(record.sensor.toString()),
                            ),
                            title: Text(
                              '${record.state.shortCode} ${record.state.description}',
                            ),
                            subtitle: Text(
                              '${record.elapsedTimeFormatted} • ${formatReceivedAt(record.receivedAt)}',
                            ),
                            trailing: Text('Boot ${record.bootSession}'),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
