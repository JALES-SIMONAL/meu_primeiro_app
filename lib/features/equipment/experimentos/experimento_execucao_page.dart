import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

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
            if (emAndamento) ...[
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
