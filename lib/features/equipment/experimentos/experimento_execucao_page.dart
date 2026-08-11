import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
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
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final device = state.selectedDevice?.device;
    final emAndamento = device?.experimentActive == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Rodar experimento livre')),
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
                        'Repeticao ${device?.repetitionCurrent ?? '-'} de ${device?.repetitionsTotal ?? '-'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Tempo decorrido: ${device?.experimentElapsedSeconds ?? 0}s',
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
                  FilledButton(
                    onPressed: controller.finishRepetition,
                    child: const Text('Finalizar repeticao'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reiniciar repeticao?'),
                          content: const Text(
                            'Os eventos ja registrados nesta repeticao serao descartados.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Nao'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Sim'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) controller.restartRepetition();
                    },
                    child: const Text('Reiniciar repeticao'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancelar experimento?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Nao'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Sim'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) controller.cancelExperiment();
                    },
                    child: const Text('Cancelar experimento'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Eventos ao vivo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(child: _EventosAoVivo(eventos: state.liveExperimentEvents)),
            ] else ...[
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _repetitionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Repeticoes'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => controller.startExperiment(
                  int.tryParse(_repetitionsController.text) ?? 1,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Medicao salva como "$nome.csv".')));
      return;
    }

    if (resultado.nomeExiste) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nome ja existe'),
          content: Text(
            'Ja existe um arquivo "$nome.csv" no equipamento. Sobrescrever?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nao'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sobrescrever'),
            ),
          ],
        ),
      );
      if (confirmar == true && mounted) await _salvar(sobrescrever: true);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel salvar a medicao. Tente novamente.'),
        ),
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
              'Medicao finalizada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'De um nome ao arquivo antes de salvar no equipamento. Se a '
              'conexao cair agora, os eventos recebidos ate aqui ficam '
              'salvos em "Rascunhos locais".',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeController,
              autofocus: true,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: const InputDecoration(labelText: 'Nome do arquivo'),
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
                label: const Text('Salvar'),
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
      return const Center(child: Text('Nenhum evento registrado ainda.'));
    }

    return ListView.builder(
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
                    Text('Canal ${evento.channel}'),
                    const SizedBox(width: 24),
                    Text(evento.state),
                  ],
                ),
              ),
              Text(formatElapsedTime(evento.timestampUs ~/ 1000)),
            ],
          ),
        );
      },
    );
  }
}
