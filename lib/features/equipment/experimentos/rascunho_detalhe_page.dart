import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/local_measurement_draft.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/csv_export_tiles.dart';

/// Detalhe de um rascunho local (ver RascunhosLocaisPage/LocalDraftStore):
/// medição finalizada no equipamento mas ainda sem nome salvo, capturada
/// localmente. Baixar/Compartilhar funcionam sem BLE (o conteúdo já está no
/// disco do app); "Enviar ao equipamento" precisa de conexão.
class RascunhoDetalhePage extends ConsumerStatefulWidget {
  const RascunhoDetalhePage({super.key, required this.rascunho});

  final LocalMeasurementDraft rascunho;

  @override
  ConsumerState<RascunhoDetalhePage> createState() =>
      _RascunhoDetalhePageState();
}

class _RascunhoDetalhePageState extends ConsumerState<RascunhoDetalhePage> {
  late final _nomeController = TextEditingController(
    text: widget.rascunho.suggestedName,
  );
  bool _enviando = false;
  bool _excluido = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<String?> _buscarConteudo() {
    return ref
        .read(appControllerProvider.notifier)
        .readLocalDraftContent(widget.rascunho.id);
  }

  Future<void> _enviarAoEquipamento({bool sobrescrever = false}) async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) return;

    setState(() => _enviando = true);
    final resultado = await ref
        .read(appControllerProvider.notifier)
        .saveMeasurementName(nome, sobrescrever: sobrescrever);
    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.ok) {
      // AppController já apaga o rascunho local ao ver aguardando_nome
      // voltar a false — aqui é só navegar de volta.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (resultado.nomeExiste) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nome ja existe'),
          content: Text(
            'Ja existe um arquivo "$nome.csv" no equipamento. Sobrescrever?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nao'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sobrescrever'),
            ),
          ],
        ),
      );
      if (confirmar == true && mounted) {
        await _enviarAoEquipamento(sobrescrever: true);
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel enviar ao equipamento. Verifique a conexao '
            'e se ha uma medicao aguardando nome nele.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleConectado = ref.watch(appControllerProvider).bleConnected;

    return Scaffold(
      appBar: AppBar(title: Text(widget.rascunho.suggestedName)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              widget.rascunho.deviceLabel ?? 'Equipamento desconhecido',
            ),
            subtitle: Text(
              'Criado ${formatRelativeAge(widget.rascunho.createdAt)}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nomeController,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Nome do arquivo',
                helperText: 'Ate 20 caracteres, so letras e numeros',
              ),
            ),
          ),
          BorderedListTile(
            leading: _enviando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_outlined),
            title: const Text('Enviar ao equipamento'),
            subtitle: Text(
              bleConectado
                  ? 'Salva com esse nome no cartao SD do equipamento'
                  : 'Precisa estar conectado via Bluetooth',
            ),
            onTap: (_enviando || !bleConectado)
                ? null
                : () => _enviarAoEquipamento(),
          ),
          CsvExportTiles(
            nomeBase: widget.rascunho.suggestedName,
            buscarConteudo: _buscarConteudo,
            assuntoCompartilhar: '${widget.rascunho.suggestedName}.csv',
          ),
          BorderedListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Excluir rascunho'),
            subtitle: const Text(
              'Descarta a copia local. Se os dados nao foram salvos no '
              'equipamento, eles se perdem.',
            ),
            onTap: _excluido
                ? null
                : () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir rascunho?'),
                        content: const Text(
                          'Essa acao nao pode ser desfeita.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Nao'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sim'),
                          ),
                        ],
                      ),
                    );
                    if (confirmar == true) {
                      await ref
                          .read(appControllerProvider.notifier)
                          .deleteLocalDraft(widget.rascunho.id);
                      _excluido = true;
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
          ),
        ],
      ),
    );
  }
}
