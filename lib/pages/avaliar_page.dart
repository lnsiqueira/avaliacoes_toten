import 'package:avaliacao_toten/models/filial_model.dart';
import 'package:avaliacao_toten/pages/caixa_texto_widget.dart';
import 'package:avaliacao_toten/pages/header_widget.dart';
import 'package:flutter/material.dart';

// class FilialSelecionadaWidget extends StatelessWidget {
//   final FilialModel model;
//   const FilialSelecionadaWidget({super.key, required this.model});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Filial Selecionada')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Apelido: ${model.apelido}',
//                 style: const TextStyle(fontSize: 18)),
//             const SizedBox(height: 8),
//             Text('Código Empresa: ${model.codEmpresa}'),
//             Text('Filial: ${model.filial}'),
//             Text('Usuário API: ${model.userApiBratter}'),
//             Text('Senha API: ${model.passwordApiBratter}'),
//             Text('URL API: ${model.urlApiBratter}'),
//           ],
//         ),
//       ),
//     );
//   }
// }

enum Avaliacao {
  completamenteInsatisfeito,
  insatisfeito,
  indiferente,
  satisfeito,
  completamenteSatisfeito,
}

extension AvaliacaoDescricao on Avaliacao {
  String get descricao {
    switch (this) {
      case Avaliacao.completamenteInsatisfeito:
        return 'Completamente insatisfeito';
      case Avaliacao.insatisfeito:
        return 'Insatisfeito';
      case Avaliacao.indiferente:
        return 'Indiferente';
      case Avaliacao.satisfeito:
        return 'Satisfeito';
      case Avaliacao.completamenteSatisfeito:
        return 'Completamente satisfeito';
    }
  }

  String get emoji {
    switch (this) {
      case Avaliacao.completamenteInsatisfeito:
        return '😡';
      case Avaliacao.insatisfeito:
        return '🙁';
      case Avaliacao.indiferente:
        return '😐';
      case Avaliacao.satisfeito:
        return '🙂';
      case Avaliacao.completamenteSatisfeito:
        return '😍';
    }
  }
}

class EmojiSelector extends StatelessWidget {
  final Avaliacao? selected;
  final ValueChanged<Avaliacao> onChanged;

  const EmojiSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: Avaliacao.values.map((avaliacao) {
        final isSelected = selected == avaliacao;

        return GestureDetector(
          onTap: () => onChanged(avaliacao),
          child: AnimatedScale(
            scale: isSelected ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.4,
              child: Text(
                avaliacao.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaginaAvaliacao extends StatefulWidget {
  const PaginaAvaliacao({super.key});

  @override
  State<PaginaAvaliacao> createState() => _PaginaAvaliacaoState();
}

class _PaginaAvaliacaoState extends State<PaginaAvaliacao> {
  final Map<String, List<String>> secoes = {
    'Qualidade dos produtos': [
      'Sabor e qualidade',
      'Temperatura',
      'Variedade dos produtos',
    ],
    'Buffet do almoço': [
      'Apresentação dos pratos',
      'Variedade dos pratos',
      'Qualidade dos pratos',
    ],
    'Atendimento': [
      'O atendente foi cordial e atencioso?',
      'O atendente sugeriu produtos?',
      'O caixa foi ágil e atencioso?',
    ],
    'Estrutura': [
      'Uniforme dos funcionários adequado?',
    ],
    'Pergunta Final': [
      'Qual é o seu grau de satisfação geral com o espaço Dona Deôla?',
    ],
  };

  final Map<String, Avaliacao?> respostas = {};

  @override
  void initState() {
    super.initState();
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espaço Dona Deôla'),
      ),
      body: Column(
        children: [
          HeaderWidget(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: secoes.entries.expand((entry) {
                final secao = entry.key;
                final perguntas = entry.value;
                return [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text(
                      secao,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(181, 228, 136, 74),
                      ),
                    ),
                  ),
                  ...perguntas.map((pergunta) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  pergunta,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 5,
                                child: EmojiSelector(
                                  selected: respostas[pergunta],
                                  onChanged: (value) {
                                    setState(() {
                                      respostas[pergunta] = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ];
              }).toList(),
            ),
          ),
          // CustomerInfoForm(),
        ],
      ),
    );
  }
}
