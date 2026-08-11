import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/zebra_row.dart';
import 'analise_distancia_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseEventos: toque no primeiro
/// evento marca o início do intervalo (equivalente ao "*" da tela física),
/// toque no segundo calcula e segue para a tela de distância. Layout de
/// tabela igual ao de ArquivoDadosPage ("Ver dados"), mas com o tempo
/// relativo ao primeiro evento da repetição (tempo de coleta) em vez do
/// timestamp bruto do equipamento.
class AnaliseEventosPage extends ConsumerStatefulWidget {
  const AnaliseEventosPage({super.key});

  @override
  ConsumerState<AnaliseEventosPage> createState() => _AnaliseEventosPageState();
}

class _AnaliseEventosPageState extends ConsumerState<AnaliseEventosPage> {
  AnalysisEvent? _inicio;

  @override
  Widget build(BuildContext context) {
    final eventos = ref.watch(appControllerProvider).loadedAnalysisEvents;

    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      body: eventos.isEmpty
          ? const Center(child: Text('Repeticao sem eventos.'))
          : Column(
              children: [
                const _EventosCabecalho(),
                Expanded(
                  child: ListView.builder(
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final evento = eventos[index];
                      final marcado = identical(evento, _inicio);
                      final tempoDeColetaMs =
                          evento.deltaUsFrom(eventos.first) ~/ 1000;
                      return ZebraRow(
                        index: index,
                        selected: marcado,
                        onTap: () {
                          if (_inicio == null) {
                            setState(() => _inicio = evento);
                            return;
                          }
                          final inicio = _inicio!;
                          setState(() => _inicio = null);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnaliseDistanciaPage(
                                inicio: inicio,
                                fim: evento,
                              ),
                            ),
                          );
                        },
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
                            Text(formatElapsedTime(tempoDeColetaMs)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EventosCabecalho extends StatelessWidget {
  const _EventosCabecalho();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('#', style: estilo)),
          Expanded(child: Text('Canal / Estado', style: estilo)),
          Text('Tempo de coleta', style: estilo),
        ],
      ),
    );
  }
}
