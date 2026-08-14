import 'package:flutter/material.dart';

/// Linha de tabela com fundo alternado conforme o indice, no mesmo padrao
/// usado pela tabela de dados do arquivo (ArquivoDadosPage) — usado em
/// qualquer lista tabular do app (dispositivos BLE, eventos, dados do
/// arquivo). Cores vêm do ColorScheme (não fixas) para funcionar em light e
/// dark mode.
class ZebraRow extends StatelessWidget {
  const ZebraRow({
    super.key,
    required this.index,
    required this.child,
    this.onTap,
    this.selected = false,
  });

  final int index;
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final corDeFundo = selected
        ? colorScheme.primaryContainer
        : (index.isEven ? colorScheme.surface : colorScheme.surfaceContainerHighest);
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
