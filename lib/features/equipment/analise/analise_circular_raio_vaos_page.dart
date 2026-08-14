import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';
import 'analise_circular_resultado_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseCircularRaioVaos: raio do
/// encoder (mm) e quantidade de vãos (fendas) por volta, mesmos limites do
/// firmware (ANALISE_CIRCULAR_RAIO_MIN_MM..MAX_MM, ..._VAOS_MIN..MAX).
/// "Calcular" busca todas as repetições do arquivo por BLE e roda
/// CircularAnalysisCalculator localmente (ver AppController.runCircularAnalysis).
class AnaliseCircularRaioVaosPage extends ConsumerStatefulWidget {
  const AnaliseCircularRaioVaosPage({super.key, required this.arquivo});

  final String arquivo;

  @override
  ConsumerState<AnaliseCircularRaioVaosPage> createState() =>
      _AnaliseCircularRaioVaosPageState();
}

class _AnaliseCircularRaioVaosPageState
    extends ConsumerState<AnaliseCircularRaioVaosPage> {
  static const _raioMinMm = 1;
  static const _raioMaxMm = 500;
  static const _vaosMin = 1;
  static const _vaosMax = 200;

  late int _raioMm;
  late int _vaosQtd;

  @override
  void initState() {
    super.initState();
    final state = ref.read(appControllerProvider);
    _raioMm = state.circularRaioMm;
    _vaosQtd = state.circularVaosQtd;
  }

  Future<void> _calcular() async {
    final controller = ref.read(appControllerProvider.notifier);
    await controller.runCircularAnalysis(
      widget.arquivo,
      raioMm: _raioMm,
      vaosQtd: _vaosQtd,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnaliseCircularResultadoPage(arquivo: widget.arquivo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carregando = ref.watch(
      appControllerProvider.select((s) => s.circularAnalysisLoading),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('circularRaioVaos.title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ValueStepper(
              label: context.tr('circularRaioVaos.radiusLabel'),
              suffix: 'mm',
              value: _raioMm,
              min: _raioMinMm,
              max: _raioMaxMm,
              onChanged: (v) => setState(() => _raioMm = v),
            ),
            const SizedBox(height: 16),
            _ValueStepper(
              label: context.tr('circularRaioVaos.gapsLabel'),
              value: _vaosQtd,
              min: _vaosMin,
              max: _vaosMax,
              onChanged: (v) => setState(() => _vaosQtd = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: carregando ? null : _calcular,
              icon: carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(context.tr('circularRaioVaos.calculate')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueStepper extends StatelessWidget {
  const _ValueStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text(
              suffix == null ? '$value' : '$value$suffix',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
