import 'package:flutter/material.dart';

/// ListTile clicavel com os limites (borda) claramente demarcados,
/// para uso em qualquer lista de opcoes/botoes de navegacao.
class BorderedListTile extends StatelessWidget {
  const BorderedListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing = const Icon(Icons.chevron_right),
    this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        enabled: enabled,
        selected: selected,
      ),
    );
  }
}
