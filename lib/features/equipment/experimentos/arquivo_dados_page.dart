import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

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
    final state = ref.watch(appControllerProvider);
    final linhas = state.fileDataRows;

    // A página pedida já chegou (a lista cresceu além do que tinha antes do
    // pedido, ou o arquivo acabou): libera o gatilho para a próxima rolagem.
    if (_carregandoMais &&
        (!state.fileDataHasMore || linhas.length > _quantidadeAoIniciarCarga)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _carregandoMais = false);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('Dados: ${widget.arquivo}')),
      body: linhas.isEmpty
          ? const Center(child: Text('Sem dados (ou SD indisponivel).'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: linhas.length + (state.fileDataHasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= linhas.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final linha = linhas[index];
                final corDeFundo = index.isEven
                    ? Colors.white
                    : const Color(0xFFEFF2F4);
                return Container(
                  decoration: BoxDecoration(
                    color: corDeFundo,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text('R${linha.repetition}')),
                      Expanded(
                        child: Text('Canal ${linha.channel} ${linha.state}'),
                      ),
                      Text('${linha.timestampUs}us'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
