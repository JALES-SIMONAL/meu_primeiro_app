import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/device_file.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'arquivo_dados_page.dart';
import 'arquivo_renomear_page.dart';

/// Equivalente a maquina_estados::Tela::ArquivoDetalhe +
/// ArquivoExcluirConfirmar — mais Compartilhar/Baixar, sem equivalente na
/// tela física (o equipamento não tem como enviar o arquivo para fora do
/// cartão SD sozinho).
class ArquivoDetalhePage extends ConsumerStatefulWidget {
  const ArquivoDetalhePage({super.key, required this.arquivo});

  final DeviceFile arquivo;

  @override
  ConsumerState<ArquivoDetalhePage> createState() =>
      _ArquivoDetalhePageState();
}

class _ArquivoDetalhePageState extends ConsumerState<ArquivoDetalhePage> {
  bool _processando = false;

  String get _nomeBase {
    final nome = widget.arquivo.name;
    final semExtensao = nome.toLowerCase().endsWith('.csv')
        ? nome.substring(0, nome.length - 4)
        : nome;
    return semExtensao.isEmpty ? 'arquivo' : semExtensao;
  }

  /// Busca o conteúdo do arquivo (paginado via BLE, ver
  /// AppController.downloadFileContent) uma única vez, reaproveitado tanto
  /// por Compartilhar quanto por Baixar.
  Future<String?> _buscarConteudo() async {
    setState(() => _processando = true);
    try {
      final conteudo = await ref
          .read(appControllerProvider.notifier)
          .downloadFileContent(widget.arquivo.name);
      if (conteudo == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo vazio ou sem resposta do equipamento.'),
          ),
        );
      }
      return conteudo;
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _compartilhar() async {
    final conteudo = await _buscarConteudo();
    if (conteudo == null || !mounted) return;

    try {
      final bytes = Uint8List.fromList(utf8.encode(conteudo));
      final arquivoTemporario = XFile.fromData(bytes, mimeType: 'text/csv');
      // XFile.fromData ignora o parametro "name" na maioria das plataformas
      // (inclusive Android) — o nome real do arquivo compartilhado só é
      // respeitado via fileNameOverrides.
      await SharePlus.instance.share(
        ShareParams(
          files: [arquivoTemporario],
          fileNameOverrides: ['$_nomeBase.csv'],
          subject: widget.arquivo.name,
        ),
      );
    } catch (error) {
      if (mounted) _mostrarErro('Nao foi possivel compartilhar: $error');
    }
  }

  Future<void> _baixar() async {
    final conteudo = await _buscarConteudo();
    if (conteudo == null || !mounted) return;

    try {
      final bytes = Uint8List.fromList(utf8.encode(conteudo));
      // saveFile() salva silenciosamente numa pasta privada do app
      // (Android/data/<pacote>/files/), invisivel no gerenciador de
      // arquivos do usuario — saveAs() abre o dialogo nativo "Salvar como",
      // deixando o usuario escolher o local (ex.: Downloads) e confirmando
      // visualmente que o download aconteceu.
      final caminho = await FileSaver.instance.saveAs(
        name: _nomeBase,
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      if (caminho == null) return; // usuario cancelou o dialogo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.arquivo.name} salvo em $caminho')),
        );
      }
    } catch (error) {
      if (mounted) _mostrarErro('Nao foi possivel baixar: $error');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider.notifier);
    final arquivo = widget.arquivo;

    return Scaffold(
      appBar: AppBar(title: Text(arquivo.name)),
      body: ListView(
        children: [
          ListTile(title: Text('Tamanho: ${arquivo.sizeBytes} bytes')),
          const SizedBox(height: 8),
          BorderedListTile(
            leading: const Icon(Icons.table_rows_outlined),
            title: const Text('Ver dados'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArquivoDadosPage(arquivo: arquivo.name),
              ),
            ),
          ),
          BorderedListTile(
            leading: _processando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            title: const Text('Compartilhar'),
            subtitle: const Text('Email, Drive, WhatsApp e outros apps'),
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
            title: const Text('Baixar'),
            subtitle: const Text('Salvar o arquivo direto no dispositivo'),
            onTap: _processando ? null : _baixar,
          ),
          BorderedListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Renomear'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArquivoRenomearPage(nomeAtual: arquivo.name),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Excluir'),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Excluir ${arquivo.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Nao'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sim'),
                    ),
                  ],
                ),
              );
              if (confirmar == true) {
                controller.deleteFile(arquivo.name);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
