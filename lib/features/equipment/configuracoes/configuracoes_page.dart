import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/ble_required_gate.dart';
import '../../../widgets/senha_dialog.dart';
import '../experimentos/conexao_app_page.dart';
import 'config_canais_page.dart';
import 'manual_page.dart';
import 'modo_operacao_page.dart';
import 'level_edit_page.dart';
import 'sobre_page.dart';

/// Equivalente a maquina_estados::Tela::Configuracoes.
class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analiseHabilitada = ref.watch(
      appControllerProvider.select(
        (s) => s.selectedDevice?.device.dataAnalysisEnabled ?? true,
      ),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('equipmentSettings.title'))),
      body: BleRequiredGate(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            BorderedListTile(
              leading: const Icon(Icons.bluetooth_connected),
              title: Text(context.tr('equipmentSettings.appConnection')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConexaoAppPage()),
              ),
            ),
            BorderedListTile(
              leading: const Icon(Icons.settings_input_component),
              title: Text(context.tr('equipmentSettings.operationMode')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ModoOperacaoPage()),
              ),
            ),
            BorderedListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(context.tr('equipmentSettings.brightness')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LevelEditPage(
                    title: context.tr('equipmentSettings.brightness'),
                    initialValue:
                        ref
                            .read(appControllerProvider)
                            .selectedDevice
                            ?.device
                            .brightness ??
                        0,
                    onChanged: controller.setBrightness,
                  ),
                ),
              ),
            ),
            BorderedListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(context.tr('equipmentSettings.volume')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LevelEditPage(
                    title: context.tr('equipmentSettings.volume'),
                    initialValue:
                        ref
                            .read(appControllerProvider)
                            .selectedDevice
                            ?.device
                            .volume ??
                        0,
                    onChanged: controller.setVolume,
                  ),
                ),
              ),
            ),
            BorderedListTile(
              leading: const Icon(Icons.sensors),
              title: Text(context.tr('equipmentSettings.channelConfig')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConfigCanaisPage()),
              ),
            ),
            BorderedListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(context.tr('equipmentSettings.manual')),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ManualPage())),
            ),
            BorderedListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr('equipmentSettings.about')),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SobrePage())),
            ),
            BorderedListTile(
              leading: const Icon(Icons.query_stats),
              title: Text(context.tr('equipmentSettings.dataAnalysis')),
              subtitle: Text(
                analiseHabilitada
                    ? context.tr('equipmentSettings.dataAnalysisEnabled')
                    : context.tr('equipmentSettings.dataAnalysisDisabled'),
              ),
              trailing: Switch(
                value: analiseHabilitada,
                onChanged: (novoValor) async {
                  final ok = await executarComSenha(
                    context,
                    ref,
                    ({senha}) => controller.setDataAnalysisEnabled(
                      novoValor,
                      senha: senha,
                    ),
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('equipmentSettings.changeError'))),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
