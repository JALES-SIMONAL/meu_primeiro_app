import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'analise_circular_raio_vaos_page.dart';
import 'analise_eventos_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseTipo: escolha entre a análise
/// linear (fluxo existente: dois eventos + distância -> velocidade) e a de
/// movimento circular (raio + vãos -> distância + gráficos de velocidade/
/// aceleração/RPM). Substitui a antiga tela "Selecionar repetição", removida
/// também no firmware por não ter função real nesse fluxo (o arquivo sempre
/// carrega a primeira repetição aqui, igual ao equipamento físico).
class AnaliseTipoPage extends ConsumerStatefulWidget {
  const AnaliseTipoPage({super.key, required this.arquivo});

  final String arquivo;

  @override
  ConsumerState<AnaliseTipoPage> createState() => _AnaliseTipoPageState();
}

class _AnaliseTipoPageState extends ConsumerState<AnaliseTipoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appControllerProvider.notifier)
          .loadRepetition(widget.arquivo, 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tipo de analise: ${widget.arquivo}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BorderedListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Analise linear'),
            subtitle: const Text(
              'Velocidade entre dois eventos e uma distancia',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnaliseEventosPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.rotate_right),
            title: const Text('Mov. circular'),
            subtitle: const Text('Raio e vaos: velocidade, aceleracao e RPM'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AnaliseCircularRaioVaosPage(arquivo: widget.arquivo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
