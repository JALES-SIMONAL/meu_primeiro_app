import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/channel_edge_mode.dart';
import '../../../models/channel_live_state.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/channel_config_sheet.dart';
import '../../../widgets/edge_mode_icon.dart';
import '../../../widgets/signal_level_icon.dart';

/// Equivalente a maquina_estados::Tela::TesteCanais — nível ao vivo de cada
/// canal, alimentado pela mensagem BLE "teste_canais" (publicada a cada
/// ~300ms independente da tela atual no display físico). Cada canal também
/// tem um botão de configuração (modo de borda) ao lado — configurar e
/// testar ficam na mesma tela, sem trocar de aba.
class TesteCanaisPage extends ConsumerStatefulWidget {
  const TesteCanaisPage({super.key});

  @override
  ConsumerState<TesteCanaisPage> createState() => _TesteCanaisPageState();
}

/// Duração da piscada do LED "virtual" ao registrar um evento de canal —
/// espelha DURACAO_PISCA_LED_MS do firmware (experimentos.cpp), só que
/// menor que o intervalo de publicação de "teste_canais" (~300ms) para o
/// efeito ficar perceptível como piscada, não como estado permanente.
const _duracaoPiscada = Duration(milliseconds: 200);

class _TesteCanaisPageState extends ConsumerState<TesteCanaisPage> {
  final Map<int, int> _ultimaContagem = {};
  final Map<int, Timer> _timersPiscada = {};
  final Set<int> _canaisPiscando = {};

  @override
  void initState() {
    super.initState();
    // Sem isto, os NeoPixels físicos só acendiam durante um teste de canais
    // feito localmente (encoder) — o firmware só aciona os LEDs quando sabe
    // que a tela de teste está aberta, e um teste iniciado só pelo app não
    // avisava o firmware disso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(appControllerProvider.notifier);
      controller.setChannelTestActive(true);
      // Garante que o botão de config. de cada canal mostre o modo
      // realmente atual, mesmo se o usuário abriu esta tela sem antes
      // passar por Configurações (que também pede isto sob demanda).
      controller.getChannels();
    });
  }

  @override
  void dispose() {
    for (final timer in _timersPiscada.values) {
      timer.cancel();
    }
    ref.read(appControllerProvider.notifier).setChannelTestActive(false);
    super.dispose();
  }

  void _registrarEventos(List<ChannelLiveState> canais) {
    for (final canal in canais) {
      final anterior = _ultimaContagem[canal.channel];
      if (anterior != null && anterior != canal.changeCount) {
        _piscar(canal.channel);
      }
      _ultimaContagem[canal.channel] = canal.changeCount;
    }
  }

  void _piscar(int canal) {
    _timersPiscada[canal]?.cancel();
    setState(() => _canaisPiscando.add(canal));
    _timersPiscada[canal] = Timer(_duracaoPiscada, () {
      if (!mounted) return;
      setState(() => _canaisPiscando.remove(canal));
    });
  }

  void _abrirConfigCanal(int canal) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // manageLiveTest: false — esta tela já liga o teste de canais remoto
      // para si mesma (initState acima) e continua aberta por baixo do
      // sheet; deixar o sheet também gerenciar isso desligaria o teste ao
      // fechá-lo, mesmo com esta tela ainda visível.
      builder: (context) => ChannelConfigSheet(canal: canal, manageLiveTest: false),
    );
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

  @override
  Widget build(BuildContext context) {
    ref.listen(appControllerProvider.select((s) => s.channelLiveStates), (previous, next) {
      _registrarEventos(next);
    });

    final (canais, channelConfigs) = ref.watch(
      appControllerProvider.select((s) => (s.channelLiveStates, s.channelConfigs)),
    );
    final configs = {for (final c in channelConfigs) c.channel: c.mode};

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('channelTest.title')),
        actions: [
          IconButton(
            tooltip: context.tr('channelConfig.restoreDefaults'),
            icon: const Icon(Icons.restore),
            onPressed: _restaurarPadrao,
          ),
        ],
      ),
      body: canais.isEmpty
          ? Center(child: Text(context.tr('channelTest.waiting')))
          : ListView(
              children: [
                for (final canal in canais)
                  _CanalTile(
                    canal: canal,
                    piscando: _canaisPiscando.contains(canal.channel),
                    modo: configs[canal.channel] ?? ChannelEdgeMode.both,
                    onConfigurar: () => _abrirConfigCanal(canal.channel),
                  ),
              ],
            ),
    );
  }
}

class _CanalTile extends StatelessWidget {
  final ChannelLiveState canal;
  final bool piscando;
  final ChannelEdgeMode modo;
  final VoidCallback onConfigurar;

  const _CanalTile({
    required this.canal,
    required this.piscando,
    required this.modo,
    required this.onConfigurar,
  });

  @override
  Widget build(BuildContext context) {
    // High=verde, Low=vermelho — mesmas cores do selo SignalLevelIcon. A cor
    // nunca é o único sinal: o selo sempre traz a letra "H"/"L" junto.
    final colorScheme = Theme.of(context).colorScheme;
    final corBase = canal.high ? AppColors.levelHigh : colorScheme.error;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      color: piscando ? corBase.withValues(alpha: 0.15) : Colors.transparent,
      child: ListTile(
        leading: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: piscando ? 1.15 : 1.0,
          child: SignalLevelIcon(high: canal.high),
        ),
        title: Text(context.tr('channelConfig.channelLabel', params: {'n': '${canal.channel}'})),
        subtitle: Text(
          '${canal.high ? context.tr('channelTest.high') : context.tr('channelTest.low')} • '
          '${context.tr('channelTest.changesCount', params: {'count': '${canal.changeCount}'})}',
        ),
        trailing: _BotaoConfigCanal(modo: modo, onPressed: onConfigurar),
      ),
    );
  }
}

/// Botão de configuração do canal: mostra o modo de borda ATUAL (ícone +
/// rótulo) e, ao ser pressionado, abre o bottom sheet de edição
/// (ChannelConfigSheet) — configurar e testar o canal ficam disponíveis na
/// mesma tela, sem navegar para Configurações.
class _BotaoConfigCanal extends StatelessWidget {
  const _BotaoConfigCanal({required this.modo, required this.onPressed});

  final ChannelEdgeMode modo;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: EdgeModeIcon(mode: modo, size: 20),
      label: Text(modo.trLabel(context)),
      onPressed: onPressed,
    );
  }
}
