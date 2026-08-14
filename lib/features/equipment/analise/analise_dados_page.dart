import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/ble_required_gate.dart';
import '../experimentos/gerenciamento_arquivos_page.dart';
import 'analise_circular_raio_vaos_page.dart';
import 'analise_eventos_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseSelecionarArquivo — reaproveita
/// a mesma lista de arquivos do Gerenciamento (mensagem BLE "files"). Usada
/// como corpo de uma das abas principais do AppShell (sem Scaffold/AppBar
/// proprios).
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

  // Equivalente a maquina_estados::Tela::AnaliseTipo, achatado num bottom
  // sheet em vez de uma página própria: um toque a menos entre escolher o
  // arquivo e escolher o tipo de análise.
  Future<void> _escolherTipo(String arquivo) async {
    ref.read(appControllerProvider.notifier).loadRepetition(arquivo, 0);

    final tipo = await showModalBottomSheet<_TipoAnalise>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TipoAnaliseSheet(arquivo: arquivo),
    );
    if (tipo == null || !mounted) return;

    switch (tipo) {
      case _TipoAnalise.linear:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnaliseEventosPage()),
        );
      case _TipoAnalise.circular:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnaliseCircularRaioVaosPage(arquivo: arquivo),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BleRequiredGate(
      child: DeviceFileListView(
        onTap: (arquivo) => _escolherTipo(arquivo.name),
      ),
    );
  }
}

enum _TipoAnalise { linear, circular }

class _TipoAnaliseSheet extends StatelessWidget {
  const _TipoAnaliseSheet({required this.arquivo});

  final String arquivo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('analysis.typeTitle', params: {'file': arquivo}),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(context.tr('analysis.linear')),
              subtitle: Text(context.tr('analysis.linearSubtitle')),
              onTap: () => Navigator.of(context).pop(_TipoAnalise.linear),
            ),
            ListTile(
              leading: const Icon(Icons.rotate_right),
              title: Text(context.tr('analysis.circular')),
              subtitle: Text(context.tr('analysis.circularSubtitle')),
              onTap: () => Navigator.of(context).pop(_TipoAnalise.circular),
            ),
          ],
        ),
      ),
    );
  }
}
