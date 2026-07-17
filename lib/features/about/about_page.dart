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
                'Versao visual atual do logger para ESP32 com MQTT e CSV.',
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
                          'Compatibilidade prevista: Windows Desktop, Android e Web.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Baseado em Riverpod, com separacao entre modelos, servicos e telas.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A interface utiliza um logo vetorial quando a imagem BMP nao existe no workspace.',
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
