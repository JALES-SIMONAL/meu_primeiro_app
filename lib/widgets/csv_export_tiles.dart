import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart' show getSaveLocation;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n/app_localizations.dart';
import 'bordered_list_tile.dart';

/// Linhas "Compartilhar"/"Baixar" reaproveitadas por qualquer tela que
/// exporte um CSV — arquivo do equipamento (ArquivoDetalhePage) ou rascunho
/// local (RascunhoDetalhePage). [buscarConteudo] busca o texto do CSV sob
/// demanda (via BLE ou leitura local, conforme a origem); [nomeBase] (sem
/// extensão) monta o nome do arquivo salvo/compartilhado.
///
/// Compartilhar só aparece fora do Windows: o Share nativo do Windows
/// (DataTransferManager) tem suporte raro/instavel a apps-alvo no
/// ecossistema desktop — fora do controle do app — e falha mostrando um
/// dialogo nativo de erro sem alternativa confiavel.
class CsvExportTiles extends StatefulWidget {
  const CsvExportTiles({
    super.key,
    required this.nomeBase,
    required this.buscarConteudo,
    this.assuntoCompartilhar,
  });

  final String nomeBase;
  final Future<String?> Function() buscarConteudo;
  final String? assuntoCompartilhar;

  @override
  State<CsvExportTiles> createState() => _CsvExportTilesState();
}

class _CsvExportTilesState extends State<CsvExportTiles> {
  bool _processando = false;

  Future<String?> _buscar() async {
    setState(() => _processando = true);
    try {
      final conteudo = await widget.buscarConteudo();
      if (conteudo == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('csvExport.emptyOrNoResponse'))),
        );
      }
      return conteudo;
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _compartilhar() async {
    final conteudo = await _buscar();
    if (conteudo == null || !mounted) return;

    try {
      final bytes = Uint8List.fromList(utf8.encode(conteudo));
      final caminho = await _escreverArquivoTemporario(bytes);
      final arquivoTemporario = XFile(
        caminho,
        mimeType: 'text/csv',
        name: '${widget.nomeBase}.csv',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [arquivoTemporario],
          subject: widget.assuntoCompartilhar,
        ),
      );
    } catch (error) {
      if (mounted) {
        _mostrarErro(context.tr('csvExport.shareError', params: {'error': '$error'}));
      }
    }
  }

  /// Escreve num arquivo real em disco (pasta temporaria), com o nome final
  /// ja definido, em vez de compartilhar bytes em memoria (XFile.fromData) e
  /// depender da materializacao automatica interna do share_plus.
  Future<String> _escreverArquivoTemporario(Uint8List bytes) async {
    final pastaTemp = await getTemporaryDirectory();
    final pastaArquivo = Directory(
      '${pastaTemp.path}/${DateTime.now().microsecondsSinceEpoch}',
    );
    await pastaArquivo.create(recursive: true);
    final arquivo = File('${pastaArquivo.path}/${widget.nomeBase}.csv');
    await arquivo.writeAsBytes(bytes);
    return arquivo.path;
  }

  Future<void> _baixar() async {
    final conteudo = await _buscar();
    if (conteudo == null || !mounted) return;

    try {
      final bytes = Uint8List.fromList(utf8.encode(conteudo));
      final caminho = Platform.isWindows
          ? await _baixarComFileSelector(bytes)
          : await _baixarComFileSaver(bytes);
      if (caminho == null) return; // usuario cancelou o dialogo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'csvExport.downloadedSnackbar',
                params: {'name': widget.nomeBase, 'path': caminho},
              ),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _mostrarErro(context.tr('csvExport.downloadError', params: {'error': '$error'}));
      }
    }
  }

  /// saveFile() salva silenciosamente numa pasta privada do app
  /// (`Android/data/<pacote>/files/`), invisivel no gerenciador de arquivos
  /// do usuario — saveAs() abre o dialogo nativo "Salvar como", deixando o
  /// usuario escolher o local (ex.: Downloads) e confirmando visualmente que
  /// o download aconteceu.
  Future<String?> _baixarComFileSaver(Uint8List bytes) {
    return FileSaver.instance.saveAs(
      name: widget.nomeBase,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// file_saver's saveAs no Windows usa GetSaveFileName (API legada do Win32)
  /// e escreve os bytes num std::ofstream direto em C++, sem tratamento de
  /// excecao — qualquer argumento fora do esperado derruba o processo
  /// inteiro. file_selector usa o dialogo nativo moderno (IFileSaveDialog)
  /// so pra escolher o caminho; a escrita dos bytes acontece aqui em Dart
  /// (XFile.saveTo -> File.writeAsBytes), sem passar bytes por codigo nativo.
  Future<String?> _baixarComFileSelector(Uint8List bytes) async {
    final nomeSugerido = '${widget.nomeBase}.csv';
    final local = await getSaveLocation(suggestedName: nomeSugerido);
    if (local == null) return null; // usuario cancelou o dialogo

    final arquivoTemporario = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: nomeSugerido,
    );
    await arquivoTemporario.saveTo(local.path);
    return local.path;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!Platform.isWindows)
          BorderedListTile(
            leading: _processando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            title: Text(context.tr('csvExport.share')),
            subtitle: Text(context.tr('csvExport.shareSubtitle')),
            onTap: _processando ? null : _compartilhar,
          ),
        BorderedListTile(
          leading: _processando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          title: Text(context.tr('csvExport.download')),
          subtitle: Text(context.tr('csvExport.downloadSubtitle')),
          onTap: _processando ? null : _baixar,
        ),
      ],
    );
  }
}
