import 'package:flutter/material.dart';

/// Linha de tabela com fundo alternado (branco / cinza claro) conforme o
/// indice, no mesmo padrao usado pela tabela de dados do arquivo
/// (ArquivoDadosPage) — usado em qualquer lista tabular do app (dispositivos
/// BLE, eventos, dados do arquivo).
class ZebraRow extends StatelessWidget {
  const ZebraRow({
    super.key,
    required this.index,
    required this.child,
    this.onTap,
    this.selected = false,
  });

  static const _corPar = Colors.white;
  static const _corImpar = Color(0xFFEFF2F4);
  static const _corSelecionada = Color(0xFFE8F5E9);

  final int index;
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final corDeFundo = selected
        ? _corSelecionada
        : (index.isEven ? _corPar : _corImpar);
    return Material(
      color: corDeFundo,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}
