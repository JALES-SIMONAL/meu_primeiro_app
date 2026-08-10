import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../experimentos/gerenciamento_arquivos_page.dart';
import 'analise_tipo_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseSelecionarArquivo — reaproveita
/// a mesma lista de arquivos do Gerenciamento (mensagem BLE "files").
class AnaliseDadosPage extends ConsumerStatefulWidget {
  const AnaliseDadosPage({super.key});

  @override
  ConsumerState<AnaliseDadosPage> createState() => _AnaliseDadosPageState();
}

class _AnaliseDadosPageState extends ConsumerState<AnaliseDadosPage> {
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
      appBar: AppBar(title: const Text('Analise de dados')),
      body: DeviceFileListView(
        onTap: (arquivo) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnaliseTipoPage(arquivo: arquivo.name),
          ),
        ),
      ),
    );
  }
}
