import 'package:flutter/material.dart';

import '../../widgets/monkey_tech_logo.dart';
import '../../widgets/section_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Sobre',
            subtitle:
                'Versao visual atual do logger para ESP32 com Bluetooth (BLE) e CSV.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const MonkeyTechLogo(size: 120),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monkey Tech Data Logger',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Compatibilidade prevista: Windows Desktop e Android, via Bluetooth Low Energy.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Baseado em Riverpod, com separacao entre modelos, servicos e telas.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
