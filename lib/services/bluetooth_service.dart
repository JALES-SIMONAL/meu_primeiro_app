import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contrato BLE do firmware (bluetooth_app.hpp/.cpp): serviço no padrão
/// "Nordic UART Service" (NUS), anunciado com o nome "Gerador_UFRN_BT". RX é
/// escrito pelo app (comandos); TX é notificado pelo firmware (estado/
/// eventos/config de canais). Cada mensagem é um JSON de uma linha só,
/// terminado em '\n' — e pode chegar fragmentado em vários pacotes BLE, então
/// o app precisa acumular bytes até achar o delimitador antes de decodificar.
class BluetoothProtocol {
  static final Guid serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  static final Guid rxCharacteristicUuid = Guid(
    '6E400002-B5A3-F393-E0A9-E50E24DCCA9E',
  );
  static final Guid txCharacteristicUuid = Guid(
    '6E400003-B5A3-F393-E0A9-E50E24DCCA9E',
  );

  static const String deviceNamePrefix = 'Gerador_UFRN_BT';
}

class BleDeviceInfo {
  final String id;
  final String name;
  final int rssi;

  const BleDeviceInfo({required this.id, required this.name, required this.rssi});

  bool get isKnownDevice => name.startsWith(BluetoothProtocol.deviceNamePrefix);
}

enum BleConnectionStateUi { disconnected, connecting, connected, disconnecting }

abstract class BluetoothAppService {
  Stream<List<BleDeviceInfo>> get scanResults;
  Stream<BleConnectionStateUi> get connectionStateChanges;

  /// Uma mensagem JSON completa (já reassemblada) por evento.
  Stream<String> get lines;

  bool get isScanning;
  bool get isConnected;
  String? get connectedDeviceId;

  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  void sendCommand(Map<String, dynamic> action);
}

class FlutterBlueService implements BluetoothAppService {
  final _scanResultsController = StreamController<List<BleDeviceInfo>>.broadcast();
  final _connectionController =
      StreamController<BleConnectionStateUi>.broadcast();
  final _linesController = StreamController<String>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  final List<int> _rxBuffer = [];

  bool _scanning = false;
  bool _connected = false;

  @override
  Stream<List<BleDeviceInfo>> get scanResults => _scanResultsController.stream;

  @override
  Stream<BleConnectionStateUi> get connectionStateChanges =>
      _connectionController.stream;

  @override
  Stream<String> get lines => _linesController.stream;

  @override
  bool get isScanning => _scanning;

  @override
  bool get isConnected => _connected;

  @override
  String? get connectedDeviceId => _device?.remoteId.str;

  Future<void> _requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
    } catch (_) {
      // Plataforma sem suporte ao plugin de permissões: segue sem bloquear,
      // o próprio scan do sistema operacional vai recusar se faltar acesso.
    }
  }

  @override
  Future<void> startScan() async {
    await _requestPermissions();
    await stopScan();
    _scanning = true;

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = [
        for (final result in results)
          BleDeviceInfo(
            id: result.device.remoteId.str,
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.advertisementData.advName,
            rssi: result.rssi,
          ),
      ];
      _scanResultsController.add(devices);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    _scanning = false;
  }

  @override
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_scanning) {
      await FlutterBluePlus.stopScan();
      _scanning = false;
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    await stopScan();
    _connectionController.add(BleConnectionStateUi.connecting);

    final device = BluetoothDevice.fromId(deviceId);
    _device = device;

    _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connected = false;
        _rxBuffer.clear();
        _connectionController.add(BleConnectionStateUi.disconnected);
      }
    });

    try {
      // Uso não comercial (projeto acadêmico/educacional da UFRN) — ver
      // enum License em flutter_blue_plus para os termos completos.
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 10),
      );

      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == BluetoothProtocol.serviceUuid,
        orElse: () => throw StateError('Servico NUS nao encontrado no dispositivo'),
      );

      final txCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == BluetoothProtocol.txCharacteristicUuid,
      );
      final rxCharacteristic = service.characteristics.firstWhere(
        (c) => c.uuid == BluetoothProtocol.rxCharacteristicUuid,
      );
      _rxCharacteristic = rxCharacteristic;

      await txCharacteristic.setNotifyValue(true);
      _notifySubscription?.cancel();
      _notifySubscription = txCharacteristic.lastValueStream.listen(_onDataReceived);

      _connected = true;
      _connectionController.add(BleConnectionStateUi.connected);
    } catch (error) {
      _connected = false;
      await device.disconnect();
      _connectionController.add(BleConnectionStateUi.disconnected);
      rethrow;
    }
  }

  void _onDataReceived(List<int> chunk) {
    if (chunk.isEmpty) return;
    _rxBuffer.addAll(chunk);

    while (true) {
      final newlineIndex = _rxBuffer.indexOf(0x0A); // '\n'
      if (newlineIndex == -1) break;

      final lineBytes = _rxBuffer.sublist(0, newlineIndex);
      _rxBuffer.removeRange(0, newlineIndex + 1);

      if (lineBytes.isEmpty) continue;
      final line = utf8.decode(lineBytes, allowMalformed: true).trim();
      if (line.isNotEmpty) _linesController.add(line);
    }
  }

  @override
  Future<void> disconnect() async {
    _connectionController.add(BleConnectionStateUi.disconnecting);
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;
    await _device?.disconnect();
    _device = null;
    _rxCharacteristic = null;
    _rxBuffer.clear();
    _connected = false;
    _connectionController.add(BleConnectionStateUi.disconnected);
  }

  @override
  void sendCommand(Map<String, dynamic> action) {
    final characteristic = _rxCharacteristic;
    if (characteristic == null || !_connected) return;

    final payload = '${jsonEncode(action)}\n';
    characteristic.write(utf8.encode(payload), withoutResponse: true);
  }
}
