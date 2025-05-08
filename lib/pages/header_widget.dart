import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> emojis = [
      {'emoji': '😡', 'label': 'Muito Insatisfeito'},
      {'emoji': '😞', 'label': 'Insatisfeito'},
      {'emoji': '😐', 'label': 'Neutro'},
      {'emoji': '😊', 'label': 'Satisfeito'},
      {'emoji': '😍', 'label': 'Muito Satisfeito'},
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todas as questões foram configuradas para que as respostas sejam fechadas. Em cada uma delas, marque a carinha que melhor representa o seu grau de satisfação com nossos serviços e produtos.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis.map((emoji) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji['emoji']!,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      emoji['label']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
