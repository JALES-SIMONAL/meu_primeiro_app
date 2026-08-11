/// Uma medição finalizada no equipamento (última repetição concluída) que
/// ainda não foi salva com nome no cartão SD, capturada localmente no
/// celular/PC a partir dos eventos recebidos ao vivo via BLE ("topico":
/// "event") — rede de segurança para o caso de queda de conexão (ou o app
/// fechar) antes do usuário nomear/salvar no equipamento. Ver
/// LocalDraftStore.
class LocalMeasurementDraft {
  final String id;
  final String suggestedName;
  final DateTime createdAt;
  final String? deviceLabel;

  const LocalMeasurementDraft({
    required this.id,
    required this.suggestedName,
    required this.createdAt,
    this.deviceLabel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'suggestedName': suggestedName,
    'createdAt': createdAt.toIso8601String(),
    'deviceLabel': deviceLabel,
  };

  factory LocalMeasurementDraft.fromJson(Map<String, dynamic> json) {
    return LocalMeasurementDraft(
      id: json['id'] as String,
      suggestedName: json['suggestedName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deviceLabel: json['deviceLabel'] as String?,
    );
  }
}
