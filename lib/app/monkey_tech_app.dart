import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/shell/app_shell.dart';

class MonkeyTechApp extends StatelessWidget {
  const MonkeyTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monkey Tech Data Logger',
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
