/// Um evento carregado de uma repetição salva (mensagem BLE
/// "topico":"analise_eventos"), equivalente a analise_dados::EventoLido.
class AnalysisEvent {
  final int channel;
  final String state;
  final int timestampUs;

  const AnalysisEvent({
    required this.channel,
    required this.state,
    required this.timestampUs,
  });

  /// delta_t_us = tempo(this) - tempo(inicio), mesma fórmula de
  /// analise_dados::calcularIntervalo.
  int deltaUsFrom(AnalysisEvent inicio) => timestampUs - inicio.timestampUs;
}
