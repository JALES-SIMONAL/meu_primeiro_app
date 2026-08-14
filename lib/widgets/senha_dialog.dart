import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../providers/app_controller.dart';

/// Executa uma ação protegida por senha (trocar nome BLE, ativar/desativar
/// Analise de dados — ver AppController._executarAcaoProtegida), pedindo a
/// senha ao usuário só quando necessário: se já validada nesta conexão
/// (AppController.senhaValidadaNestaConexao), [acao] é chamada direto sem
/// senha (usa o cache); senão mostra o dialogo de senha primeiro. Se a
/// tentativa falhar (senha errada, cache desatualizado por ter mudado no
/// outro lado — app/equipamento), pede a senha de novo uma vez.
Future<bool> executarComSenha(
  BuildContext context,
  WidgetRef ref,
  Future<bool> Function({String? senha}) acao,
) async {
  final controller = ref.read(appControllerProvider.notifier);

  if (controller.senhaValidadaNestaConexao) {
    final ok = await acao();
    if (ok || !context.mounted) return ok;
    // Cache desatualizado (senha mudou por outro caminho): pede de novo.
    return _pedirEExecutar(context, acao);
  }

  return _pedirEExecutar(context, acao);
}

Future<bool> _pedirEExecutar(
  BuildContext context,
  Future<bool> Function({String? senha}) acao, {
  String? erro,
}) async {
  final senha = await _pedirSenha(context, erro: erro);
  if (senha == null || !context.mounted) return false;

  final ok = await acao(senha: senha);
  if (ok || !context.mounted) return ok;
  return _pedirEExecutar(context, acao, erro: context.tr('passwordDialog.incorrectRetry'));
}

Future<String?> _pedirSenha(BuildContext context, {String? erro}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('passwordDialog.title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(erro, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            maxLength: 10,
            decoration: InputDecoration(labelText: context.tr('passwordDialog.label')),
            onSubmitted: (valor) => Navigator.of(context).pop(valor),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(context.tr('common.confirm')),
        ),
      ],
    ),
  );
}
