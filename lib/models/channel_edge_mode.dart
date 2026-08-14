import 'package:flutter/widgets.dart';

import '../core/l10n/app_localizations.dart';

/// Espelha comandos::EdgeMode do firmware (canais.hpp). A representação
/// visual de cada modo (cores, selo geométrico) fica em EdgeModeIcon
/// (widgets/edge_mode_icon.dart) — este enum só guarda o valor protocolar e
/// a chave de tradução, para ter uma única fonte de verdade do desenho.
enum ChannelEdgeMode {
  falling(0, 'channelConfig.edgeFallingToLow'),
  rising(1, 'channelConfig.edgeRisingToHigh'),
  both(2, 'channelConfig.edgeBoth'),
  disabled(3, 'channelConfig.edgeDisabled');

  const ChannelEdgeMode(this.value, this.labelKey);

  final int value;
  final String labelKey;

  static ChannelEdgeMode fromValue(int value) {
    return ChannelEdgeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ChannelEdgeMode.both,
    );
  }
}

extension ChannelEdgeModeLabel on ChannelEdgeMode {
  String trLabel(BuildContext context) => context.tr(labelKey);
}

class ChannelConfig {
  final int channel;
  final ChannelEdgeMode mode;

  const ChannelConfig({required this.channel, required this.mode});
}
