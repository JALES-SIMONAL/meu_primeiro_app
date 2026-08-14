import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../models/channel_edge_mode.dart';
import '../models/channel_live_state.dart';
import '../providers/app_controller.dart';
import 'edge_mode_icon.dart';
import 'signal_level_icon.dart';

/// Conteúdo do bottom sheet de configuração de UM canal: nível ao vivo do
/// canal lado a lado com a escolha de modo — selecionar já aplica e fecha o
/// sheet, sem diálogo de confirmação extra (edição de um único canal é de
/// baixo risco/reversível). Reaproveitado por ConfigCanaisPage (aba
/// Configurações) e TesteCanaisPage (aba Experimentos > Teste de canal/
/// sensor) — configurar e testar um canal ficam acessíveis a partir dos dois
/// lugares, sem duplicar a lógica.
class ChannelConfigSheet extends ConsumerStatefulWidget {
  const ChannelConfigSheet({super.key, required this.canal, this.manageLiveTest = true});

  final int canal;

  /// Quando true (padrão), o sheet liga/desliga o teste de canais remoto
  /// (setChannelTestActive) ao abrir/fechar — correto quando aberto de uma
  /// tela que não estava testando antes (ex.: ConfigCanaisPage). Quando o
  /// sheet é aberto de dentro da própria TesteCanaisPage — que já liga o
  /// teste remoto para a tela inteira, e continua aberta por baixo do sheet
  /// — isto precisa ser false: senão, fechar o sheet desligaria o teste
  /// remoto mesmo com a tela de teste ainda visível.
  final bool manageLiveTest;

  @override
  ConsumerState<ChannelConfigSheet> createState() => _ChannelConfigSheetState();
}

class _ChannelConfigSheetState extends ConsumerState<ChannelConfigSheet> {
  @override
  void initState() {
    super.initState();
    if (widget.manageLiveTest) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(appControllerProvider.notifier).setChannelTestActive(true),
      );
    }
  }

  @override
  void dispose() {
    if (widget.manageLiveTest) {
      ref.read(appControllerProvider.notifier).setChannelTestActive(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (channelConfigs, channelLiveStates) = ref.watch(
      appControllerProvider.select((s) => (s.channelConfigs, s.channelLiveStates)),
    );
    final configs = {for (final c in channelConfigs) c.channel: c.mode};
    final modoAtual = configs[widget.canal];

    ChannelLiveState? live;
    for (final c in channelLiveStates) {
      if (c.channel == widget.canal) {
        live = c;
        break;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('channelConfig.channelLabel', params: {'n': '${widget.canal}'}),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('channelConfig.testThisChannel'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (live != null)
                  SignalLevelIcon(high: live.high)
                else
                  const SizedBox(width: 28, height: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    live == null
                        ? context.tr('channelTest.waiting')
                        : '${live.high ? context.tr('channelTest.high') : context.tr('channelTest.low')} • '
                              '${context.tr('channelTest.changesCount', params: {'count': '${live.changeCount}'})}',
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            RadioGroup<ChannelEdgeMode>(
              groupValue: modoAtual,
              onChanged: (modo) {
                if (modo == null) return;
                ref.read(appControllerProvider.notifier).setChannelMode(widget.canal, modo);
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final modo in ChannelEdgeMode.values)
                    RadioListTile<ChannelEdgeMode>(
                      value: modo,
                      secondary: EdgeModeIcon(mode: modo),
                      title: Text(modo.trLabel(context)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
