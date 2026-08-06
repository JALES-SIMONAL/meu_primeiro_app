/// Uma linha do CSV de um arquivo do equipamento (mensagem BLE
/// "topico":"dados_arquivo"), usada pela tabela rolante de dados do arquivo.
class FileDataRow {
  final int repetition;
  final int channel;
  final String state;
  final int timestampUs;

  const FileDataRow({
    required this.repetition,
    required this.channel,
    required this.state,
    required this.timestampUs,
  });
}
