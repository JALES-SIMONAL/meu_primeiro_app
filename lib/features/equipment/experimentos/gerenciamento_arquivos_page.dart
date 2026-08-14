import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/device_file.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'arquivo_detalhe_page.dart';

/// Equivalente a maquina_estados::Tela::GerenciamentoArquivos, alimentada
/// pela mensagem BLE "files" (solicitada com a ação "list_files").
class GerenciamentoArquivosPage extends ConsumerStatefulWidget {
  const GerenciamentoArquivosPage({super.key});

  @override
  ConsumerState<GerenciamentoArquivosPage> createState() =>
      _GerenciamentoArquivosPageState();
}

class _GerenciamentoArquivosPageState
    extends ConsumerState<GerenciamentoArquivosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).listFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final arquivos = ref.watch(appControllerProvider.select((s) => s.deviceFiles));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('fileManagement.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(appControllerProvider.notifier).listFiles(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DeviceFileListView(
              onTap: (arquivo) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArquivoDetalhePage(arquivo: arquivo),
                ),
              ),
            ),
          ),
          if (arquivos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: BorderedListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: Text(context.tr('fileManagement.deleteAllTitle')),
                onTap: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('fileManagement.deleteAllConfirmTitle')),
                      content: Text(context.tr('fileManagement.deleteAllConfirmContent')),
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
                  if (confirmar == true) {
                    ref.read(appControllerProvider.notifier).deleteAllFiles();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Lista de arquivos do SD do equipamento (`state.deviceFiles`), reaproveitada
/// pela análise de dados para selecionar o arquivo a analisar.
class DeviceFileListView extends ConsumerWidget {
  const DeviceFileListView({super.key, required this.onTap});

  final ValueChanged<DeviceFile> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arquivos = ref.watch(appControllerProvider.select((s) => s.deviceFiles));

    if (arquivos.isEmpty) {
      return Center(child: Text(context.tr('fileManagement.empty')));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final arquivo in arquivos)
          BorderedListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(arquivo.name),
            subtitle: Text(
              context.tr('fileManagement.sizeBytes', params: {'size': '${arquivo.sizeBytes}'}),
            ),
            onTap: () => onTap(arquivo),
          ),
      ],
    );
  }
}
