import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'analise_distancia_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseEventos: toque no primeiro
/// evento marca o início do intervalo (equivalente ao "*" da tela física),
/// toque no segundo calcula e segue para a tela de distância.
class AnaliseEventosPage extends ConsumerStatefulWidget {
  const AnaliseEventosPage({super.key});

  @override
  ConsumerState<AnaliseEventosPage> createState() => _AnaliseEventosPageState();
}

class _AnaliseEventosPageState extends ConsumerState<AnaliseEventosPage> {
  AnalysisEvent? _inicio;

  @override
  Widget build(BuildContext context) {
    final eventos = ref.watch(appControllerProvider).loadedAnalysisEvents;

    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      body: eventos.isEmpty
          ? const Center(child: Text('Repeticao sem eventos.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: eventos.length,
              itemBuilder: (context, index) {
                final evento = eventos[index];
                final marcado = identical(evento, _inicio);
                return BorderedListTile(
                  selected: marcado,
                  leading: Text('E$index'),
                  title: Text('Canal ${evento.channel} ${evento.state}'),
                  trailing: Text('${evento.timestampUs}us'),
                  onTap: () {
                    if (_inicio == null) {
                      setState(() => _inicio = evento);
                      return;
                    }
                    final inicio = _inicio!;
                    setState(() => _inicio = null);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AnaliseDistanciaPage(inicio: inicio, fim: evento),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
