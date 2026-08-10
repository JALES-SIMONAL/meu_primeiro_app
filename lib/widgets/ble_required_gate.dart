import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/bluetooth/bluetooth_page.dart';
import '../providers/app_controller.dart';

/// Envolve qualquer conteudo que dependa de uma conexao BLE ativa com o
/// equipamento: mostra [child] normalmente quando conectado, ou um aviso
/// pedindo para conectar antes de prosseguir (com atalho direto para a tela
/// de escaneamento/conexao).
class BleRequiredGate extends ConsumerWidget {
  const BleRequiredGate({super.key, required this.child, this.message});

  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(
      appControllerProvider.select((s) => s.bleConnected),
    );
    if (connected) return child;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  message ??
                      'Conecte um equipamento via Bluetooth para continuar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BluetoothPage()),
                  ),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Conectar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
