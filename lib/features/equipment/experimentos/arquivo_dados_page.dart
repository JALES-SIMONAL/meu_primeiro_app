import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/app_table_header.dart';
import '../../../widgets/signal_level_icon.dart';
import '../../../widgets/zebra_row.dart';

/// Tabela rolante com os dados brutos (canal/estado/tempo_us) do arquivo,
/// paginada sob demanda pela ação BLE "read_file_data" — sem equivalente na
/// tela física (o display do equipamento não tem essa visualização).
class ArquivoDadosPage extends ConsumerStatefulWidget {
  const ArquivoDadosPage({super.key, required this.arquivo});

  final String arquivo;

  @override
  ConsumerState<ArquivoDadosPage> createState() => _ArquivoDadosPageState();
}

class _ArquivoDadosPageState extends ConsumerState<ArquivoDadosPage> {
  final _scrollController = ScrollController();
  bool _carregandoMais = false;
  int _quantidadeAoIniciarCarga = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).readFileData(widget.arquivo, 0);
    });
    _scrollController.addListener(_aoRolar);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_aoRolar);
    _scrollController.dispose();
    super.dispose();
  }

  void _aoRolar() {
    if (_carregandoMais) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }

    final state = ref.read(appControllerProvider);
    if (!state.fileDataHasMore) return;

    setState(() {
      _carregandoMais = true;
      _quantidadeAoIniciarCarga = state.fileDataRows.length;
    });
    ref
        .read(appControllerProvider.notifier)
        .readFileData(widget.arquivo, state.fileDataRows.length);
  }

  @override
  Widget build(BuildContext context) {
    final (linhas, fileDataHasMore) = ref.watch(
      appControllerProvider.select((s) => (s.fileDataRows, s.fileDataHasMore)),
    );

    // A página pedida já chegou (a lista cresceu além do que tinha antes do
    // pedido, ou o arquivo acabou): libera o gatilho para a próxima rolagem.
    if (_carregandoMais &&
        (!fileDataHasMore || linhas.length > _quantidadeAoIniciarCarga)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _carregandoMais = false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('fileData.titlePrefix', params: {'file': widget.arquivo}),
        ),
      ),
      body: linhas.isEmpty
          ? Center(child: Text(context.tr('fileData.empty')))
          : Column(
              children: [
                AppTableHeader(
                  columns: [
                    Text(context.tr('fileData.repetition')),
                    Text(context.tr('experimentExecution.tableChannelState')),
                    Text(context.tr('experimentExecution.tableTime')),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: linhas.length + (fileDataHasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= linhas.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final linha = linhas[index];
                      return ZebraRow(
                        index: index,
                        child: Row(
                          children: [
                            SizedBox(width: 36, child: Text('R${linha.repetition}')),
                            Expanded(
                              child: Row(
                                children: [
                                  SignalLevelIcon(high: linha.state == 'H', size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    context.tr(
                                      'channelConfig.channelLabel',
                                      params: {'n': '${linha.channel}'},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text('${linha.timestampUs}us'),
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
