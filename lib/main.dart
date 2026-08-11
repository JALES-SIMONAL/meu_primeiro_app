import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/monkey_tech_app.dart';
import 'services/ble_foreground_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BleForegroundService.init();
  runApp(const ProviderScope(child: MonkeyTechApp()));
}
