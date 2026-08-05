/// Um arquivo no microSD do equipamento (mensagem BLE "topico":"files").
class DeviceFile {
  final String name;
  final int sizeBytes;

  const DeviceFile({required this.name, required this.sizeBytes});
}
