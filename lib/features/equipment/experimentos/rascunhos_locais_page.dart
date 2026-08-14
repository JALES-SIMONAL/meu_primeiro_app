import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/local_measurement_draft.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'rascunho_detalhe_page.dart';

/// Medições finalizadas no equipamento (última repetição concluída) que
/// ficaram sem nome salvo — capturadas localmente no celular/PC como rede
/// de segurança (ver LocalDraftStore/AppController._persistirRascunhoLocal).
/// Funciona mesmo sem BLE conectado: os dados já estão no armazenamento do
/// app, não no cartão SD do equipamento.
class RascunhosLocaisPage extends ConsumerStatefulWidget {
  const RascunhosLocaisPage({super.key});

  @override
  ConsumerState<RascunhosLocaisPage> createState() =>
      _RascunhosLocaisPageState();
}

class _RascunhosLocaisPageState extends ConsumerState<RascunhosLocaisPage> {
  late Future<List<LocalMeasurementDraft>> _futuro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _futuro = ref.read(appControllerProvider.notifier).listLocalDrafts();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    await _futuro;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('localDrafts.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_carregar),
          ),
        ],
      ),
      body: FutureBuilder<List<LocalMeasurementDraft>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rascunhos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: rascunhos.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.tr('localDrafts.empty')),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      for (final rascunho in rascunhos)
                        BorderedListTile(
                          leading: const Icon(Icons.drafts_outlined),
                          title: Text(rascunho.suggestedName),
                          subtitle: Text(
                            '${rascunho.deviceLabel ?? context.tr("localDrafts.unknownDevice")} • '
                            '${context.tr("localDrafts.createdAgo", params: {
                              "age": formatRelativeAge(rascunho.createdAt),
                            })}',
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RascunhoDetalhePage(rascunho: rascunho),
                              ),
                            );
                            if (mounted) setState(_carregar);
                          },
                        ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
