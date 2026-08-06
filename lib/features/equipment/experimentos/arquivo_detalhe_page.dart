import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/device_file.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'arquivo_dados_page.dart';
import 'arquivo_renomear_page.dart';

/// Equivalente a maquina_estados::Tela::ArquivoDetalhe +
/// ArquivoExcluirConfirmar.
class ArquivoDetalhePage extends ConsumerWidget {
  const ArquivoDetalhePage({super.key, required this.arquivo});

  final DeviceFile arquivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);

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
