import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arquivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(appControllerProvider.notifier).listFiles(),
          ),
        ],
      ),
      body: DeviceFileListView(
        onTap: (arquivo) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArquivoDetalhePage(arquivo: arquivo),
          ),
        ),
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
    final arquivos = ref.watch(appControllerProvider).deviceFiles;

    if (arquivos.isEmpty) {
      return const Center(child: Text('Nenhum arquivo (ou SD indisponivel).'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final arquivo in arquivos)
          BorderedListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(arquivo.name),
            subtitle: Text('${arquivo.sizeBytes} bytes'),
            onTap: () => onTap(arquivo),
          ),
      ],
    );
  }
}
