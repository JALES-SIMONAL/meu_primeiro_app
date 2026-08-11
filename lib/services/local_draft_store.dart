import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/local_measurement_draft.dart';

/// Guarda em disco (fora do cartão SD do equipamento) o CSV de medições
/// finalizadas mas ainda sem nome salvo — ver LocalMeasurementDraft. Cada
/// rascunho é um par de arquivos (`id.csv` com o conteúdo, `id.json` com os
/// metadados), na pasta de documentos do app. Sobrevive a reinícios do app
/// (ao contrário do estado em memória do AppController).
class LocalDraftStore {
  const LocalDraftStore();

  Future<Directory> _pastaRascunhos() async {
    final base = await getApplicationDocumentsDirectory();
    final pasta = Directory('${base.path}/rascunhos_medicao');
    if (!await pasta.exists()) await pasta.create(recursive: true);
    return pasta;
  }

  Future<LocalMeasurementDraft> salvar({
    required String suggestedName,
    required String csvContent,
    String? deviceLabel,
  }) async {
    final pasta = await _pastaRascunhos();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final draft = LocalMeasurementDraft(
      id: id,
      suggestedName: suggestedName,
      createdAt: DateTime.now(),
      deviceLabel: deviceLabel,
    );

    await File('${pasta.path}/$id.csv').writeAsString(csvContent);
    await File(
      '${pasta.path}/$id.json',
    ).writeAsString(jsonEncode(draft.toJson()));

    return draft;
  }

  Future<List<LocalMeasurementDraft>> listar() async {
    final pasta = await _pastaRascunhos();
    final drafts = <LocalMeasurementDraft>[];
    await for (final entidade in pasta.list()) {
      if (entidade is! File || !entidade.path.endsWith('.json')) continue;
      try {
        final json =
            jsonDecode(await entidade.readAsString()) as Map<String, dynamic>;
        drafts.add(LocalMeasurementDraft.fromJson(json));
      } catch (_) {
        // Metadado corrompido/incompleto: ignora esse rascunho em vez de
        // derrubar a listagem inteira.
      }
    }
    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return drafts;
  }

  Future<String?> lerConteudo(String id) async {
    final pasta = await _pastaRascunhos();
    final arquivo = File('${pasta.path}/$id.csv');
    if (!await arquivo.exists()) return null;
    return arquivo.readAsString();
  }

  Future<void> excluir(String id) async {
    final pasta = await _pastaRascunhos();
    for (final extensao in ['csv', 'json']) {
      final arquivo = File('${pasta.path}/$id.$extensao');
      if (await arquivo.exists()) await arquivo.delete();
    }
  }
}
