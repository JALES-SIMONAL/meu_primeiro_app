import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
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
          title: Text(context.tr('experimentExecution.nameExistsTitle')),
          content: Text(
            context.tr('experimentExecution.nameExistsContent', params: {'name': nome}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('common.no')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('experimentExecution.overwrite')),
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
        SnackBar(content: Text(context.tr('localDrafts.sendFailedSnackbar'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleConectado = ref.watch(appControllerProvider.select((s) => s.bleConnected));

    return Scaffold(
      appBar: AppBar(title: Text(widget.rascunho.suggestedName)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              widget.rascunho.deviceLabel ?? context.tr('localDrafts.unknownDevice'),
            ),
            subtitle: Text(
              context.tr(
                'localDrafts.createdAgoLabel',
                params: {'age': formatRelativeAge(widget.rascunho.createdAt)},
              ),
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
              decoration: InputDecoration(
                labelText: context.tr('localDrafts.nameLabel'),
                helperText: context.tr('localDrafts.nameHelper'),
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
            title: Text(context.tr('localDrafts.sendToDevice')),
            subtitle: Text(
              bleConectado
                  ? context.tr('localDrafts.sendToDeviceHintConnected')
                  : context.tr('localDrafts.sendToDeviceHintDisconnected'),
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
            title: Text(context.tr('localDrafts.deleteDraft')),
            subtitle: Text(context.tr('localDrafts.deleteDraftSubtitle')),
            onTap: _excluido
                ? null
                : () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.tr('localDrafts.deleteDraftConfirmTitle')),
                        content: Text(context.tr('localDrafts.irreversible')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(context.tr('common.no')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(context.tr('common.yes')),
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
