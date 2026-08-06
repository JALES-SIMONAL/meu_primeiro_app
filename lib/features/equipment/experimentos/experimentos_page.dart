import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'conexao_app_page.dart';
import 'experimento_execucao_page.dart';
import 'gerenciamento_arquivos_page.dart';
import 'teste_canais_page.dart';

/// Equivalente a maquina_estados::Tela::Experimentos.
class ExperimentosPage extends ConsumerWidget {
  const ExperimentosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Experimentos')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BorderedListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Rodar experimento livre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExperimentoExecucaoPage(),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.sensors_outlined),
            title: const Text('Teste de canal/sensor'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TesteCanaisPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Gerenciamento de arquivos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GerenciamentoArquivosPage(),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.bluetooth_connected),
            title: const Text('Conexao com app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConexaoAppPage()),
            ),
          ),
        ],
      ),
    );
  }
}
