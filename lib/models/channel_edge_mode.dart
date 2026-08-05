/// Espelha comandos::EdgeMode do firmware (canais.hpp).
enum ChannelEdgeMode {
  falling(0, 'H para L'),
  rising(1, 'L para H'),
  both(2, 'Ambos'),
  disabled(3, 'Desabilitado');

  const ChannelEdgeMode(this.value, this.label);

  final int value;
  final String label;

  static ChannelEdgeMode fromValue(int value) {
    return ChannelEdgeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ChannelEdgeMode.both,
    );
  }
}

class ChannelConfig {
  final int channel;
  final ChannelEdgeMode mode;

  const ChannelConfig({required this.channel, required this.mode});
}
