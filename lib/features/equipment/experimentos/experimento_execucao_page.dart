import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/app_table_header.dart';
import '../../../widgets/signal_level_icon.dart';
import '../../../widgets/zebra_row.dart';

/// Equivalente a maquina_estados::Tela::ExperimentoRepeticoes +
/// ExperimentoExecucao + ExperimentoCancelarConfirmar.
class ExperimentoExecucaoPage extends ConsumerStatefulWidget {
  const ExperimentoExecucaoPage({super.key});

  @override
  ConsumerState<ExperimentoExecucaoPage> createState() =>
      _ExperimentoExecucaoPageState();
}

class _ExperimentoExecucaoPageState
    extends ConsumerState<ExperimentoExecucaoPage> {
  final _repetitionsController = TextEditingController(text: '1');

  @override
  void dispose() {
    _repetitionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (device, liveExperimentEvents) = ref.watch(
      appControllerProvider.select((s) => (s.selectedDevice?.device, s.liveExperimentEvents)),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final emAndamento = device?.experimentActive == true;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('experimentExecution.title'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device?.awaitingMeasurementName == true) ...[
              _NomearMedicaoForm(suggestedName: device!.suggestedMeasurementName),
            ] else if (emAndamento) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'experimentExecution.repetitionOf',
                          params: {
                            'current': '${device?.repetitionCurrent ?? '-'}',
                            'total': '${device?.repetitionsTotal ?? '-'}',
                          },
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        context.tr(
                          'experimentExecution.elapsedTime',
                          params: {'seconds': '${device?.experimentElapsedSeconds ?? 0}'},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: controller.finishRepetition,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(context.tr('experimentExecution.finishRepetition')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            context.tr('experimentExecution.restartRepetitionConfirmTitle'),
                          ),
                          content: Text(
                            context.tr('experimentExecution.restartRepetitionConfirmContent'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(context.tr('common.no')),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(context.tr('common.yes')),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) controller.restartRepetition();
                    },
                    icon: const Icon(Icons.replay),
                    label: Text(context.tr('experimentExecution.restartRepetition')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            context.tr('experimentExecution.cancelExperimentConfirmTitle'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(context.tr('common.no')),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(context.tr('common.yes')),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) controller.cancelExperiment();
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(context.tr('experimentExecution.cancelExperiment')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('experimentExecution.liveEvents'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(child: _EventosAoVivo(eventos: liveExperimentEvents)),
            ] else ...[
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _repetitionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('experimentExecution.repetitionsLabel'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => controller.startExperiment(
                  int.tryParse(_repetitionsController.text) ?? 1,
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(context.tr('experimentExecution.start')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formulario exibido quando o equipamento termina a ultima repeticao e
/// fica aguardando um nome pra salvar a medicao (ver
/// Esp32Device.awaitingMeasurementName/suggestedMeasurementName e
/// AppController.saveMeasurementName) — equivalente a
/// maquina_estados::Tela::ExperimentoNomeArquivo no menu fisico, so que
/// digitado no teclado do celular/PC em vez de girar o encoder.
class _NomearMedicaoForm extends ConsumerStatefulWidget {
  const _NomearMedicaoForm({required this.suggestedName});

  final String suggestedName;

  @override
  ConsumerState<_NomearMedicaoForm> createState() =>
      _NomearMedicaoFormState();
}

class _NomearMedicaoFormState extends ConsumerState<_NomearMedicaoForm> {
  late final _nomeController = TextEditingController(text: widget.suggestedName);
  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar({bool sobrescrever = false}) async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    setState(() => _salvando = true);
    final resultado = await ref
        .read(appControllerProvider.notifier)
        .saveMeasurementName(nome, sobrescrever: sobrescrever);
    if (!mounted) return;
    setState(() => _salvando = false);

    if (resultado.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('experimentExecution.savedSnackbar', params: {'name': nome}),
          ),
        ),
      );
      return;
    }

    if (resultado.nomeExiste) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('experimentExecution.nameExistsTitle')),
          content: Text(
            context.tr('experimentExecution.nameExistsContent', params: {'name': nome}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('common.no')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('experimentExecution.overwrite')),
            ),
          ],
        ),
      );
      if (confirmar == true && mounted) await _salvar(sobrescrever: true);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('experimentExecution.saveFailedSnackbar'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('experimentExecution.measurementFinished'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(context.tr('experimentExecution.measurementFinishedHelp')),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeController,
              autofocus: true,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('experimentExecution.fileNameLabel'),
              ),
              onSubmitted: (_) {
                if (!_salvando) _salvar();
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _salvando ? null : () => _salvar(),
                icon: _salvando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(context.tr('common.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista dos eventos da repeticao em andamento chegando ao vivo via BLE
/// ("topico":"event"), auto-rolando para o ultimo recebido. Mesmo estilo de
/// tabela zebrada da tela "Eventos" (repeticao ja salva).
class _EventosAoVivo extends StatefulWidget {
  const _EventosAoVivo({required this.eventos});

  final List<AnalysisEvent> eventos;

  @override
  State<_EventosAoVivo> createState() => _EventosAoVivoState();
}

class _EventosAoVivoState extends State<_EventosAoVivo> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EventosAoVivo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventos.length == oldWidget.eventos.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventos.isEmpty) {
      return Center(child: Text(context.tr('experimentExecution.noEventsYet')));
    }

    return Column(
      children: [
        AppTableHeader(
          columns: [
            Text(context.tr('experimentExecution.tableIndex')),
            Text(context.tr('experimentExecution.tableChannelState')),
            Text(context.tr('experimentExecution.tableTime')),
          ],
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.eventos.length,
            itemBuilder: (context, index) {
              final evento = widget.eventos[index];
              return ZebraRow(
                index: index,
                child: Row(
                  children: [
                    SizedBox(width: 36, child: Text('E$index')),
                    Expanded(
                      child: Row(
                        children: [
                          SignalLevelIcon(high: evento.state == 'H', size: 22),
                          const SizedBox(width: 12),
                          Text(
                            context.tr(
                              'channelConfig.channelLabel',
                              params: {'n': '${evento.channel}'},
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(formatElapsedTime(evento.timestampUs ~/ 1000)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
