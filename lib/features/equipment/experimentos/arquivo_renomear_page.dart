import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ArquivoRenomear (editor de nome do
/// firmware é um alfabeto girado pelo encoder; aqui é um TextField comum).
class ArquivoRenomearPage extends ConsumerStatefulWidget {
  const ArquivoRenomearPage({super.key, required this.nomeAtual});

  final String nomeAtual;

  @override
  ConsumerState<ArquivoRenomearPage> createState() =>
      _ArquivoRenomearPageState();
}

class _ArquivoRenomearPageState extends ConsumerState<ArquivoRenomearPage> {
  late final _controller = TextEditingController(
    text: widget.nomeAtual.replaceAll(
      RegExp(r'\.csv$', caseSensitive: false),
      '',
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('fileRename.title'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 10,
              decoration: InputDecoration(labelText: context.tr('fileRename.newName')),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final novoNome = _controller.text.trim();
                if (novoNome.isEmpty) return;
                ref
                    .read(appControllerProvider.notifier)
                    .renameFile(widget.nomeAtual, novoNome);
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(context.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
