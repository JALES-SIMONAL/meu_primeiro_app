import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/ble_required_gate.dart';
import 'experimento_execucao_page.dart';
import 'gerenciamento_arquivos_page.dart';
import 'teste_canais_page.dart';

/// Equivalente a maquina_estados::Tela::Experimentos. Usada como corpo de
/// uma das abas principais do AppShell (sem Scaffold/AppBar proprios). O
/// conteúdo é estático (não depende de nenhum campo de AppState além do
/// bleConnected que BleRequiredGate já observa por conta própria), então
/// não precisa ser um ConsumerWidget — evita reconstruir esta tela a cada
/// mudança de estado não relacionada (logs, eventos ao vivo etc.).
class ExperimentosPage extends StatelessWidget {
  const ExperimentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BleRequiredGate(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BorderedListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(context.tr('experiments.runFree')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ExperimentoExecucaoPage(),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.sensors_outlined),
            title: Text(context.tr('experiments.channelTest')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TesteCanaisPage())),
          ),
          BorderedListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(context.tr('experiments.fileManagement')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GerenciamentoArquivosPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
