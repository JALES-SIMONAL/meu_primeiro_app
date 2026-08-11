import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_state.dart';
import '../../../models/channel_live_state.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::TesteCanais — nível ao vivo de cada
/// canal, alimentado pela mensagem BLE "teste_canais" (publicada a cada
/// ~300ms independente da tela atual no display físico).
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(appControllerProvider.notifier).setChannelTestActive(true),
    );
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AppState>(appControllerProvider, (previous, next) {
      _registrarEventos(next.channelLiveStates);
    });

    final canais = ref.watch(appControllerProvider).channelLiveStates;

    return Scaffold(
      appBar: AppBar(title: const Text('Teste de canais')),
      body: canais.isEmpty
          ? const Center(child: Text('Aguardando dados do equipamento...'))
          : ListView(
              children: [
                for (final canal in canais)
                  _CanalTile(
                    canal: canal,
                    piscando: _canaisPiscando.contains(canal.channel),
                  ),
              ],
            ),
    );
  }
}

class _CanalTile extends StatelessWidget {
  final ChannelLiveState canal;
  final bool piscando;

  const _CanalTile({required this.canal, required this.piscando});

  @override
  Widget build(BuildContext context) {
    // LOW=verde, HIGH=vermelho — mesma convenção do NeoPixel físico (ver
    // atualizarTelasAoVivo() em maquina_estados.cpp).
    final corBase = canal.high ? Colors.red : Colors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      color: piscando ? corBase.withValues(alpha: 0.15) : Colors.transparent,
      child: ListTile(
        leading: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: piscando ? 1.4 : 1.0,
          child: Icon(
            Icons.circle,
            color: piscando ? corBase.withValues(alpha: 1.0) : corBase,
          ),
        ),
        title: Text('Canal ${canal.channel}'),
        subtitle: Text(canal.high ? 'HIGH' : 'LOW'),
        trailing: Text('${canal.changeCount} mudancas'),
      ),
    );
  }
}
