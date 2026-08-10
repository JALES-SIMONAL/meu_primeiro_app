import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/analysis_event.dart';
import 'package:meu_primeiro_app/models/channel_edge_mode.dart';
import 'package:meu_primeiro_app/models/collection_session.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';
import 'package:meu_primeiro_app/providers/app_controller.dart';
import 'package:meu_primeiro_app/services/bluetooth_service.dart';

class _FakeBluetoothService implements BluetoothAppService {
  final _scanResultsController =
      StreamController<List<BleDeviceInfo>>.broadcast();
  final _connectionController =
      StreamController<BleConnectionStateUi>.broadcast();
  final _linesController = StreamController<String>.broadcast();

  bool _connected = false;
  String? _connectedId;
  final List<Map<String, dynamic>> sentCommands = [];

  @override
  Stream<List<BleDeviceInfo>> get scanResults => _scanResultsController.stream;

  @override
  Stream<BleConnectionStateUi> get connectionStateChanges =>
      _connectionController.stream;

  @override
  Stream<String> get lines => _linesController.stream;

  @override
  bool get isScanning => false;

  @override
  bool get isConnected => _connected;

  @override
  String? get connectedDeviceId => _connectedId;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(String deviceId) async {
    _connectedId = deviceId;
    _connected = true;
    _connectionController.add(BleConnectionStateUi.connected);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connectionController.add(BleConnectionStateUi.disconnected);
  }

  @override
  void sendCommand(Map<String, dynamic> action) => sentCommands.add(action);

  void emitLine(String line) => _linesController.add(line);

  void emitScanResults(List<BleDeviceInfo> results) =>
      _scanResultsController.add(results);

  /// Simula uma queda de conexão inesperada (sem passar por disconnect()).
  void simulateDrop() {
    _connected = false;
    _connectionController.add(BleConnectionStateUi.disconnected);
  }
}

void main() {
  late ProviderContainer container;
  late AppController controller;
  late _FakeBluetoothService fakeBt;

  setUp(() {
    fakeBt = _FakeBluetoothService();
    container = ProviderContainer(
      overrides: [
        appControllerProvider.overrideWith(
          () => AppController(bluetoothService: fakeBt),
        ),
      ],
    );
    controller = container.read(appControllerProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('locks device selection during active collection', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    controller.startCollection(fileName: 'ensaio 01');

    controller.selectDevice('OUTRO_ID');

    expect(controller.state.selectedDeviceId, 'A1B2C3');
    expect(controller.state.collectionSession?.stage, CollectionStage.running);
  });

  test('startBleScan surfaces discovered devices in state', () async {
    fakeBt.emitScanResults(const [
      BleDeviceInfo(id: 'A1B2C3', name: 'Gerador_UFRN_BT', rssi: -50),
    ]);
    await controller.startBleScan();

    expect(controller.state.bleScanResults, hasLength(1));
    expect(controller.state.bleScanResults.single.id, 'A1B2C3');
  });

  test('connectToDevice marks the device online', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.bleConnected, isTrue);
    final deviceState = controller.state.devices['A1B2C3'];
    expect(deviceState, isNotNull);
    expect(deviceState!.device.isOnline, isTrue);
  });

  test('connectToDevice sends set_datetime with the current local epoch',
      () async {
    // O firmware não tem fuso horário: o epoch enviado usa os campos do
    // horário local do celular "disfarçados" de UTC (ver
    // AppController.setDateTime), não o epoch UTC real.
    int localComoUtcAgora() {
      final agora = DateTime.now();
      return DateTime.utc(
        agora.year,
        agora.month,
        agora.day,
        agora.hour,
        agora.minute,
        agora.second,
      ).millisecondsSinceEpoch ~/
          1000;
    }

    final beforeConnect = localComoUtcAgora();
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    final afterConnect = localComoUtcAgora();

    expect(fakeBt.sentCommands, hasLength(1));
    final sent = fakeBt.sentCommands.single;
    expect(sent['action'], 'set_datetime');
    expect(
      sent['epoch'],
      inInclusiveRange(beforeConnect, afterConnect),
    );
  });

  test('ingests a real firmware event message', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'event',
        'canal': 1,
        'estado': 'H',
        'tempo_us': 2000000,
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final deviceState = controller.state.devices['A1B2C3']!;
    expect(deviceState.channels[1]!.state, SensorState.high);
    expect(deviceState.channels[1]!.timestampMs, 2000);
  });

  test('ingests a firmware state message', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'state',
        'modo_operacao': 'app',
        'brilho': 20,
        'volume': 15,
        'sd_disponivel': true,
        'sd_erros': 0,
        'experimento_ativo': false,
        'repeticao_atual': 0,
        'repeticoes_totais': 0,
        'eventos_repeticao': 0,
        'num_canais': 6,
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final device = controller.state.devices['A1B2C3']!.device;
    expect(device.brightness, 20);
    expect(device.volume, 15);
    expect(device.sdCardAvailable, isTrue);
  });

  test('reconnecting after an unexpected drop bumps the boot session', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.simulateDrop();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.devices['A1B2C3']!.device.isOnline, isFalse);

    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    final deviceState = controller.state.devices['A1B2C3']!;
    expect(deviceState.device.isOnline, isTrue);
    expect(deviceState.rebootCount, 1);
    expect(deviceState.device.bootSession, 2);
  });

  test('sendNext writes the command via the Bluetooth service', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.sendNext();

    expect(fakeBt.sentCommands, [
      {'action': 'next'},
    ]);
  });

  test('restartRepetition writes the command via the Bluetooth service',
      () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.restartRepetition();

    expect(fakeBt.sentCommands, [
      {'action': 'restart_repetition'},
    ]);
  });

  test('startExperiment resends set_datetime before start_experiment',
      () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.startExperiment(3);

    expect(fakeBt.sentCommands, hasLength(2));
    expect(fakeBt.sentCommands[0]['action'], 'set_datetime');
    expect(fakeBt.sentCommands[1], {
      'action': 'start_experiment',
      'repetitions': 3,
    });
  });

  test('ingests a firmware channels message', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'channels',
        'canais': [
          {'canal': 1, 'modo': 2},
          {'canal': 2, 'modo': 3},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.channelConfigs, hasLength(2));
    expect(controller.state.channelConfigs[0].mode, ChannelEdgeMode.both);
    expect(controller.state.channelConfigs[1].mode, ChannelEdgeMode.disabled);
  });

  test('ingests a firmware info message once per connection', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'info',
        'equipamento': 'HardwareFisica',
        'versao_firmware': '1.0.0',
        'autor': 'Wilson Douglas Jales Simonal',
        'device_id': 'A1B2C3',
        'mac': 'AA:BB:CC:DD:EE:FF',
        'manual_url': 'http://example.com/manual',
        'nome_bt': 'Gerador_UFRN_BT',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    final device = controller.state.devices['A1B2C3']!.device;
    expect(device.name, 'HardwareFisica');
    expect(device.author, 'Wilson Douglas Jales Simonal');
    expect(device.macAddress, 'AA:BB:CC:DD:EE:FF');
    expect(device.manualUrl, 'http://example.com/manual');
    expect(device.bleDeviceName, 'Gerador_UFRN_BT');
  });

  test('setDeviceName sends the set_device_name command', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.setDeviceName('Novo_Nome_BT');

    expect(fakeBt.sentCommands, [
      {'action': 'set_device_name', 'nome': 'Novo_Nome_BT'},
    ]);
  });

  test('ingests a firmware teste_canais message', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'teste_canais',
        'canais': [
          {'canal': 1, 'nivel': 'H', 'mudancas': 5},
          {'canal': 2, 'nivel': 'L', 'mudancas': 0},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.channelLiveStates, hasLength(2));
    expect(controller.state.channelLiveStates[0].high, isTrue);
    expect(controller.state.channelLiveStates[0].changeCount, 5);
  });

  test('getChannels requests fresh channel config on demand', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.getChannels();

    expect(fakeBt.sentCommands, [
      {'action': 'get_channels'},
    ]);
  });

  test('list_files/rename_file/delete_file send the expected commands and '
      'files message updates state', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.listFiles();
    controller.renameFile('OLD.CSV', 'novo');
    controller.deleteFile('OUTRO.CSV');

    expect(fakeBt.sentCommands, [
      {'action': 'list_files'},
      {'action': 'rename_file', 'from': 'OLD.CSV', 'to': 'novo'},
      {'action': 'delete_file', 'nome': 'OUTRO.CSV'},
    ]);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'files',
        'arquivos': [
          {'nome': 'NOVO.CSV', 'tamanho': 1024},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.deviceFiles, hasLength(1));
    expect(controller.state.deviceFiles.single.name, 'NOVO.CSV');
    expect(controller.state.deviceFiles.single.sizeBytes, 1024);
  });

  test('loadRepetition sends the command and analise_eventos populates '
      'loadedAnalysisEvents', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.loadRepetition('ENSAIO1.CSV', 0);
    expect(fakeBt.sentCommands, [
      {'action': 'load_repetition', 'arquivo': 'ENSAIO1.CSV', 'repeticao': 0},
    ]);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'analise_eventos',
        'eventos': [
          {'canal': 1, 'estado': 'H', 'tempo_us': 1000},
          {'canal': 1, 'estado': 'L', 'tempo_us': 4000},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.loadedAnalysisEvents, hasLength(2));
  });

  test('runCircularAnalysis loops load_repetition until an empty response '
      'and aggregates the results', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    final future = controller.runCircularAnalysis(
      'ENSAIO1.CSV',
      raioMm: 100,
      vaosQtd: 4,
    );

    // A parte síncrona de runCircularAnalysis (até o primeiro "await") já
    // deve ter pedido a repetição 0 antes de suspender.
    expect(fakeBt.sentCommands, [
      {'action': 'load_repetition', 'arquivo': 'ENSAIO1.CSV', 'repeticao': 0},
    ]);
    expect(controller.state.circularAnalysisLoading, isTrue);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'analise_eventos',
        'eventos': [
          {'canal': 1, 'estado': 'H', 'tempo_us': 0},
          {'canal': 1, 'estado': 'L', 'tempo_us': 100000},
          {'canal': 1, 'estado': 'H', 'tempo_us': 200000},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(fakeBt.sentCommands, [
      {'action': 'load_repetition', 'arquivo': 'ENSAIO1.CSV', 'repeticao': 0},
      {'action': 'load_repetition', 'arquivo': 'ENSAIO1.CSV', 'repeticao': 1},
    ]);

    fakeBt.emitLine(jsonEncode({'topico': 'analise_eventos', 'eventos': []}));
    await future;

    expect(controller.state.circularAnalysisLoading, isFalse);
    expect(controller.state.circularPerRepetitionResults, hasLength(1));
    final media = controller.state.circularAverageResult;
    expect(media, isNotNull);
    expect(media!.repeticoesValidas, 1);
    expect(media.repeticoesTotais, 1);
    expect(media.velocidadeMediaMs, greaterThan(0));
  });

  test('loadCircularGraph exposes the points for the chosen series/repetition',
      () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);

    final future = controller.runCircularAnalysis(
      'ENSAIO1.CSV',
      raioMm: 100,
      vaosQtd: 4,
    );
    fakeBt.emitLine(
      jsonEncode({
        'topico': 'analise_eventos',
        'eventos': [
          {'canal': 1, 'estado': 'H', 'tempo_us': 0},
          {'canal': 1, 'estado': 'L', 'tempo_us': 100000},
          {'canal': 1, 'estado': 'H', 'tempo_us': 200000},
        ],
      }),
    );
    await Future<void>.delayed(Duration.zero);
    fakeBt.emitLine(jsonEncode({'topico': 'analise_eventos', 'eventos': []}));
    await future;

    controller.loadCircularGraph(kind: 'rpm', repeticaoIndice: 0);

    expect(controller.state.circularGraphTitle, 'RPM');
    expect(controller.state.circularGraphPoints, hasLength(2));
  });

  test('readFileData sends the command and dados_arquivo populates '
      'fileDataRows (offset 0 replaces, offset>0 appends)', () async {
    await controller.connectToDevice('A1B2C3');
    await Future<void>.delayed(Duration.zero);
    fakeBt.sentCommands.clear();

    controller.readFileData('ENSAIO1.CSV', 0);
    expect(fakeBt.sentCommands, [
      {'action': 'read_file_data', 'arquivo': 'ENSAIO1.CSV', 'offset': 0},
    ]);

    fakeBt.emitLine(
      jsonEncode({
        'topico': 'dados_arquivo',
        'arquivo': 'ENSAIO1.CSV',
        'offset': 0,
        'linhas': [
          {'repeticao': 0, 'canal': 1, 'estado': 'H', 'tempo_us': 1000},
          {'repeticao': 0, 'canal': 1, 'estado': 'L', 'tempo_us': 4000},
        ],
        'tem_mais': true,
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.fileDataRows, hasLength(2));
    expect(controller.state.fileDataHasMore, isTrue);

    controller.readFileData('ENSAIO1.CSV', 2);
    fakeBt.emitLine(
      jsonEncode({
        'topico': 'dados_arquivo',
        'arquivo': 'ENSAIO1.CSV',
        'offset': 2,
        'linhas': [
          {'repeticao': 1, 'canal': 2, 'estado': 'H', 'tempo_us': 8000},
        ],
        'tem_mais': false,
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.fileDataRows, hasLength(3));
    expect(controller.state.fileDataHasMore, isFalse);
  });

  test('computeAnalysisResult replicates analise_dados.cpp formula', () {
    const inicio = AnalysisEvent(channel: 1, state: 'H', timestampUs: 1000);
    const fim = AnalysisEvent(channel: 1, state: 'L', timestampUs: 501000);

    final resultado = controller.computeAnalysisResult(inicio, fim, 100);

    expect(resultado.deltaTUs, 500000);
    expect(resultado.velocidadeMs, closeTo(2.0, 0.0001));
  });
}
