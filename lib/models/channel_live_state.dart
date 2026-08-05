/// Nível elétrico ao vivo de um canal (mensagem BLE "topico":"teste_canais"),
/// equivalente à tela física "Teste de canais".
class ChannelLiveState {
  final int channel;
  final bool high;
  final int changeCount;

  const ChannelLiveState({
    required this.channel,
    required this.high,
    required this.changeCount,
  });
}
