import 'package:flutter/material.dart';

/// Slider 0-30 reaproveitado por Brilho e Volume (configuracoes::NIVEL_MINIMO/
/// NIVEL_MAXIMO) — equivalente às telas maquina_estados::Tela::Brilho/Volume,
/// só que com controle direto por slider em vez do editor de encoder.
class LevelEditPage extends StatefulWidget {
  const LevelEditPage({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onChanged,
  });

  final String title;
  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  State<LevelEditPage> createState() => _LevelEditPageState();
}

class _LevelEditPageState extends State<LevelEditPage> {
  late double _value = widget.initialValue.toDouble().clamp(0, 30);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _value.round().toString(),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Slider(
              min: 0,
              max: 30,
              divisions: 30,
              value: _value,
              label: _value.round().toString(),
              onChanged: (next) => setState(() => _value = next),
              onChangeEnd: (next) => widget.onChanged(next.round()),
            ),
          ],
        ),
      ),
    );
  }
}
