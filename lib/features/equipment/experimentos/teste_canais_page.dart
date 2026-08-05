import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::TesteCanais — nível ao vivo de cada
/// canal, alimentado pela mensagem BLE "teste_canais" (publicada a cada
/// ~300ms independente da tela atual no display físico).
class TesteCanaisPage extends ConsumerWidget {
  const TesteCanaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canais = ref.watch(appControllerProvider).channelLiveStates;

    return Scaffold(
      appBar: AppBar(title: const Text('Teste de canais')),
      body: canais.isEmpty
          ? const Center(child: Text('Aguardando dados do equipamento...'))
          : ListView(
              children: [
                for (final canal in canais)
                  ListTile(
                    leading: Icon(
                      Icons.circle,
                      color: canal.high ? Colors.green : Colors.red,
                    ),
                    title: Text('Canal ${canal.channel}'),
                    subtitle: Text(canal.high ? 'HIGH' : 'LOW'),
                    trailing: Text('${canal.changeCount} mudancas'),
                  ),
              ],
            ),
    );
  }
}
