import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/device_file.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/csv_export_tiles.dart';
import 'arquivo_dados_page.dart';
import 'arquivo_renomear_page.dart';

/// Equivalente a maquina_estados::Tela::ArquivoDetalhe +
/// ArquivoExcluirConfirmar — mais Compartilhar/Baixar (ver CsvExportTiles),
/// sem equivalente na tela física (o equipamento não tem como enviar o
/// arquivo para fora do cartão SD sozinho).
class ArquivoDetalhePage extends ConsumerStatefulWidget {
  const ArquivoDetalhePage({super.key, required this.arquivo});

  final DeviceFile arquivo;

  @override
  ConsumerState<ArquivoDetalhePage> createState() =>
      _ArquivoDetalhePageState();
}

class _ArquivoDetalhePageState extends ConsumerState<ArquivoDetalhePage> {
  String get _nomeBase {
    final nome = widget.arquivo.name;
    final semExtensao = nome.toLowerCase().endsWith('.csv')
        ? nome.substring(0, nome.length - 4)
        : nome;
    return semExtensao.isEmpty ? 'arquivo' : semExtensao;
  }

  Future<String?> _buscarConteudo() {
    return ref
        .read(appControllerProvider.notifier)
        .downloadFileContent(widget.arquivo.name);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider.notifier);
    final arquivo = widget.arquivo;

    return Scaffold(
      appBar: AppBar(title: Text(arquivo.name)),
      body: ListView(
        children: [
          ListTile(title: Text('Tamanho: ${arquivo.sizeBytes} bytes')),
          const SizedBox(height: 8),
          BorderedListTile(
            leading: const Icon(Icons.table_rows_outlined),
            title: const Text('Ver dados'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArquivoDadosPage(arquivo: arquivo.name),
              ),
            ),
          ),
          CsvExportTiles(
            nomeBase: _nomeBase,
            buscarConteudo: _buscarConteudo,
            assuntoCompartilhar: arquivo.name,
          ),
          BorderedListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Renomear'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArquivoRenomearPage(nomeAtual: arquivo.name),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Excluir'),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Excluir ${arquivo.name}?'),
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
              if (confirmar == true) {
                controller.deleteFile(arquivo.name);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
