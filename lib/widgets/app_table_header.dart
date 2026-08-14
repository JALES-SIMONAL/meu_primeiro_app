import 'package:flutter/material.dart';

/// Cabeçalho de tabela padronizado (MD3): usa `primaryContainer` do tema
/// para dar destaque estrutural às colunas, em vez de um cinza neutro —
/// reaproveitado por todas as tabelas de eventos/dados do app (Eventos,
/// Ver dados, execução do experimento).
class AppTableHeader extends StatelessWidget {
  const AppTableHeader({super.key, required this.columns});

  /// Um `Widget` por coluna — normalmente `Text`, mas aceita qualquer
  /// widget (ex.: ícone). A primeira coluna é fixa em 36px (mesma largura
  /// do índice "#"/"En" usado nas tabelas de eventos); as demais dividem o
  /// espaço restante igualmente.
  final List<Widget> columns;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onPrimaryContainer,
    );

    return DefaultTextStyle.merge(
      style: labelStyle,
      child: IconTheme.merge(
        data: IconThemeData(color: colorScheme.onPrimaryContainer),
        child: Container(
          color: colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              for (final (index, column) in columns.indexed) ...[
                if (index == 0) SizedBox(width: 36, child: column) else Expanded(child: column),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
