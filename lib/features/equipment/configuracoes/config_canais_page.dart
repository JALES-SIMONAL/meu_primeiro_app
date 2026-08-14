import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/channel_edge_mode.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/channel_config_sheet.dart';
import '../../../widgets/edge_mode_icon.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanais + ConfigCanaisIndividualLista
/// + ConfigCanaisIndividualEditar/Confirmar + ConfigCanaisVisualizar, tudo
/// achatado numa única tela: a lista já mostra o modo atual de cada canal, e
/// tocar num canal abre um bottom sheet (ChannelConfigSheet) com a escolha de
/// modo E o nível ao vivo do canal lado a lado — configurar e testar sem
/// trocar de tela nem empilhar páginas (Configurar todos/Restaurar viraram
/// ações da AppBar). O mesmo sheet também é aberto a partir de
/// TesteCanaisPage — ver comentário em ChannelConfigSheet.
class ConfigCanaisPage extends ConsumerStatefulWidget {
  const ConfigCanaisPage({super.key});

  @override
  ConsumerState<ConfigCanaisPage> createState() => _ConfigCanaisPageState();
}

class _ConfigCanaisPageState extends ConsumerState<ConfigCanaisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).getChannels();
    });
  }

  Future<void> _restaurarPadrao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('channelConfig.restoreConfirmTitle')),
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
    if (confirmar == true && mounted) {
      ref.read(appControllerProvider.notifier).restoreChannelDefaults();
    }
  }

  Future<void> _configurarTodos() async {
    final modo = await showModalBottomSheet<ChannelEdgeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SeletorModoSheet(
        titulo: context.tr('channelConfig.configureAll'),
      ),
    );
    if (modo == null || !mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('channelConfig.applyAllConfirmTitle')),
        content: Text(modo.trLabel(context)),
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
    if (confirmar == true && mounted) {
      ref.read(appControllerProvider.notifier).setAllChannelsMode(modo);
    }
  }

  void _abrirCanal(int canal) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ChannelConfigSheet(canal: canal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (channelCount, channelConfigs) = ref.watch(
      appControllerProvider.select(
        (s) => (s.selectedDevice?.device.channelCount ?? 6, s.channelConfigs),
      ),
    );
    final configs = {for (final c in channelConfigs) c.channel: c.mode};

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('channelConfig.title')),
        actions: [
          IconButton(
            tooltip: context.tr('channelConfig.configureAll'),
            icon: const Icon(Icons.checklist_rtl),
            onPressed: _configurarTodos,
          ),
          IconButton(
            tooltip: context.tr('channelConfig.restoreDefaults'),
            icon: const Icon(Icons.restore),
            onPressed: _restaurarPadrao,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var canal = 1; canal <= channelCount; canal++)
            BorderedListTile(
              leading: EdgeModeIcon(mode: configs[canal] ?? ChannelEdgeMode.both),
              title: Text(context.tr('channelConfig.channelLabel', params: {'n': '$canal'})),
              trailing: Chip(label: Text(configs[canal]?.trLabel(context) ?? '?')),
              onTap: () => _abrirCanal(canal),
            ),
        ],
      ),
    );
  }
}

/// Seletor de modo genérico (sem canal/teste associado) — usado por
/// "Configurar todos".
class _SeletorModoSheet extends StatelessWidget {
  const _SeletorModoSheet({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final modo in ChannelEdgeMode.values)
              ListTile(
                leading: EdgeModeIcon(mode: modo),
                title: Text(modo.trLabel(context)),
                onTap: () => Navigator.of(context).pop(modo),
              ),
          ],
        ),
      ),
    );
  }
}
