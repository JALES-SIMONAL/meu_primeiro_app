import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/app_table_header.dart';
import '../../../widgets/signal_level_icon.dart';
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
    final eventos = ref.watch(appControllerProvider.select((s) => s.loadedAnalysisEvents));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('analysisEvents.title'))),
      body: eventos.isEmpty
          ? Center(child: Text(context.tr('analysisEvents.empty')))
          : Column(
              children: [
                AppTableHeader(
                  columns: [
                    Text(context.tr('analysisEvents.tableIndex')),
                    Text(context.tr('analysisEvents.tableChannelState')),
                    Text(context.tr('analysisEvents.tableCollectionTime')),
                  ],
                ),
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
