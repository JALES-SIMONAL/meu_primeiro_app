import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import 'analise_eventos_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseSelecionarRepeticao.
class AnaliseSelecionarRepeticaoPage extends ConsumerStatefulWidget {
  const AnaliseSelecionarRepeticaoPage({super.key, required this.arquivo});

  final String arquivo;

  @override
  ConsumerState<AnaliseSelecionarRepeticaoPage> createState() =>
      _AnaliseSelecionarRepeticaoPageState();
}

class _AnaliseSelecionarRepeticaoPageState
    extends ConsumerState<AnaliseSelecionarRepeticaoPage> {
  int _repeticao = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Repeticao: ${widget.arquivo}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _repeticao > 0
                      ? () => setState(() => _repeticao--)
                      : null,
                ),
                Text(
                  '$_repeticao',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _repeticao++),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref
                    .read(appControllerProvider.notifier)
                    .loadRepetition(widget.arquivo, _repeticao);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnaliseEventosPage(),
                  ),
                );
              },
              child: const Text('Carregar'),
            ),
          ],
        ),
      ),
    );
  }
}
