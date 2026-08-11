import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Mantem o processo do app vivo em segundo plano no Android enquanto
/// conectado ao equipamento via BLE, atraves de um foreground service com
/// notificacao persistente — sem isso o Android pode encerrar o processo
/// (economia de bateria/memoria) minutos depois do usuario trocar de app,
/// derrubando a conexao BLE.
///
/// So faz sentido no Android (unica plataforma suportada pelo plugin):
/// Windows nao suspende o processo em segundo plano por si so (ver
/// windows/runner/win32_window.cpp — WM_SIZE so redimensiona, nao pausa
/// nada), entao nao precisa disso la. O BLE em si (flutter_blue_plus)
/// continua rodando inteiramente na isolate principal — este servico so
/// existe pra manter o processo "relevante" pro sistema operacional, sem
/// nenhuma logica de BLE dentro da task isolate dele (misturar os dois nao
/// funciona: https://github.com/Dev-hwang/flutter_foreground_task/issues/84).
class BleForegroundService {
  BleForegroundService._();

  static const String _channelId = 'ble_connection_service';
  static const int _serviceId = 4001;

  static bool get _suportado => !kIsWeb && Platform.isAndroid;

  static bool _inicializado = false;

  /// Chamar uma unica vez, antes de runApp().
  static void init() {
    if (!_suportado || _inicializado) return;
    _inicializado = true;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Conexao Bluetooth',
        channelDescription:
            'Mantem a conexao com o equipamento ativa em segundo plano.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  /// Inicia o foreground service (idempotente — nao faz nada se ja estiver
  /// rodando). [rotuloDispositivo] aparece no texto da notificacao.
  static Future<void> start(
    String rotuloDispositivo, {
    void Function(String mensagem)? onError,
  }) async {
    if (!_suportado) return;
    try {
      final permissao = await FlutterForegroundTask.checkNotificationPermission();
      if (permissao != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (await FlutterForegroundTask.isRunningService) return;

      final resultado = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: const [ForegroundServiceTypes.connectedDevice],
        notificationTitle: 'Conectado ao equipamento',
        notificationText: rotuloDispositivo,
        callback: _startCallback,
      );
      if (resultado is ServiceRequestFailure) {
        onError?.call(
          'Nao foi possivel manter a conexao em segundo plano: ${resultado.error}',
        );
      }
    } catch (error) {
      onError?.call('Nao foi possivel manter a conexao em segundo plano: $error');
    }
  }

  static Future<void> stop() async {
    if (!_suportado) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.stopService();
    } catch (_) {
      // Sem app conectado nesse ponto de qualquer forma — nada a fazer se a
      // parada falhar (ex.: servico ja tinha sido encerrado pelo sistema).
    }
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_NoopTaskHandler());
}

/// Nao faz nada por si so: o BLE roda todo na isolate principal
/// (FlutterBlueService/AppController). Este handler so precisa existir pra
/// o foreground service ter uma task valida e permanecer ativo.
class _NoopTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
