import 'package:avaliacao_toten/models/filial_model.dart';
import 'package:avaliacao_toten/pages/header_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            scale: isSelected ? 1.6 : 1.3,
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
  final FilialModel model;
  const PaginaAvaliacao({super.key, required this.model});

  @override
  State<PaginaAvaliacao> createState() => _PaginaAvaliacaoState();
}

class _PaginaAvaliacaoState extends State<PaginaAvaliacao> {
  final ScrollController _scrollController = ScrollController();
  int? _avaliacao; // Armazena a avaliação do usuário
  bool _respondendoPesquisa = false;

  Future<void> enviarAvaliacaoParaFirestore() async {
    final todosVazios = _nomeController.text.isEmpty &&
        _cpfController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _commentsController.text.isEmpty &&
        respostas.isEmpty;

    if (todosVazios) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Atenção'),
          content: const Text(
              'Preencha pelo menos um campo para enviar a avaliação.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final filialModel = FilialModel(
        id: prefs.getString('id') ?? widget.model.id,
        apelido: prefs.getString('apelido') ?? '',
        codEmpresa: prefs.getString('codEmpresa') ?? '',
        filial: prefs.getString('filial') ?? '',
        passwordApiBratter: prefs.getString('passwordApiBratter') ?? '',
        urlApiBratter: prefs.getString('urlApiBratter') ?? '',
        userApiBratter: prefs.getString('userApiBratter') ?? '',
      );

      if (filialModel.id.isEmpty) {
        throw Exception('ID da filial não encontrado');
      }

      final Map<String, dynamic> dados = {
        'comentario': _commentsController.text,
        'cpf': _cpfController.text,
        'nome': _nomeController.text,
        'email': _emailController.text,
        'avaliacoes': respostas.map((pergunta, avaliacao) {
          return MapEntry(pergunta, avaliacao?.toString() ?? 'Não respondido');
        }),
        'data_envio': FieldValue.serverTimestamp(),
        'codEmpresa': filialModel.codEmpresa,
        'codFilial': filialModel.id,
      };

      final filialDocRef = FirebaseFirestore.instance
          .collection('filiais_avaliacoes')
          .doc(filialModel.id);

      final docSnapshot = await filialDocRef.get();

      if (!docSnapshot.exists) {
        await filialDocRef.set({
          'filial_id': filialModel.id,
          'nome_filial': filialModel.apelido,
          'data_criacao': FieldValue.serverTimestamp(),
          'total_avaliacoes': 0,
        });
      }

      await filialDocRef.collection('avaliacoes').add(dados);

      await filialDocRef.update({
        'total_avaliacoes': FieldValue.increment(1),
        'ultima_avaliacao': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avaliação enviada com sucesso!')),
      );

      await _mostrarFeedback(context);
      _showSurveyPopup();

      _nomeController.clear();
      _cpfController.clear();
      _emailController.clear();
      _commentsController.clear();
      setState(() => respostas.clear());
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: Text('Falha ao enviar: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _mostrarFeedback(BuildContext context) async {
    // Aguarda o delay antes de mostrar o dialog
    await Future.delayed(Duration(milliseconds: 500));

    // Mostra o dialog e aguarda até que seja fechado
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Obrigado!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up, color: Colors.green, size: 50),
              SizedBox(height: 16),
              Text(
                'Agradecemos sua participação na pesquisa!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );

    // Código aqui será executado após o dialog ser fechado
    print('Dialog fechado');
  }

  // void _mostrarFeedback(BuildContext context) {
  //   // Mostra o popup de agradecimento após um pequeno delay
  //   Future.delayed(Duration(milliseconds: 500), () {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Text('Obrigado!', textAlign: TextAlign.center),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(Icons.thumb_up, color: Colors.green, size: 50),
  //               SizedBox(height: 16),
  //               Text(
  //                 'Agradecemos sua participação na pesquisa!',
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(fontSize: 16),
  //               ),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               child: Text('Fechar'),
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ],
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //         );
  //       },
  //     );
  //   });
  // }

  void _showSurveyPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo-padaria.png',
                height: 100,
                width: 100,
              ),
              SizedBox(height: 20),
              Text(
                'Ajude-nos a melhorar!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Por favor, avalie sua experiência conosco:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Componente de avaliação com estrelas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      _avaliacao != null && index < _avaliacao!
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _avaliacao = index + 1;
                      });
                    },
                  );
                }),
              ),
              SizedBox(height: 20),
              if (_avaliacao != null)
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Comentários (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: Text('Ok'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.brown,
                  //   ),
                  //   child: Text('Ok'),
                  //   onPressed: _avaliacao != null
                  //       ? () {
                  //           setState(() {
                  //             _respondendoPesquisa = false;
                  //           });
                  //           Navigator.pop(context);
                  //           // _mostrarAgradecimento();
                  //         }
                  //       : null,
                  // ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
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
  final FocusNode _commentsFocusNode = FocusNode();
  final FocusNode _cpfFocusNode = FocusNode();
  final FocusNode _nomeFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  var maskFormatter = new MaskTextInputFormatter(
      mask: '(##)#####-####', filter: {"#": RegExp(r'[0-9]')});

  final double _keyboardPadding = 300;

  final Map<String, Avaliacao?> respostas = {};

  @override
  void initState() {
    super.initState();
    _commentsFocusNode.addListener(_scrollToEmail);
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });

    _cpfFocusNode.addListener(_scrollToEmail);
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });

    _nomeFocusNode.addListener(_scrollToEmail);
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });

    _phoneFocusNode.addListener(_scrollToEmail);
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });

    _emailFocusNode.addListener(_scrollToEmail);
    secoes.values.expand((list) => list).forEach((pergunta) {
      respostas[pergunta] = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _showSurveyPopup());
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _cpfController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    _commentsFocusNode.dispose();
    _cpfFocusNode.dispose();
    _nomeFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();

    super.dispose();
  }

  void _scrollToEmail() {
    if (_commentsFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }

    if (_cpfFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
    if (_nomeFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
    if (_nomeFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
    if (_emailFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
    if (_phoneFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + _keyboardPadding,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _limparFormulario() {
    setState(() {
      _commentsController.clear();
      _cpfController.clear();
      _nomeController.clear();
      _phoneController.clear();
      _emailController.clear();

      for (var key in respostas.keys) {
        respostas[key] = null;
      }

      _commentsFocusNode.unfocus();
      _cpfFocusNode.unfocus();
      _nomeFocusNode.unfocus();
      _phoneFocusNode.unfocus();
      _emailFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Espaço Dona Deôla',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 228, 136, 74),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                try {
                  await enviarAvaliacaoParaFirestore();

                  _limparFormulario();

                  _scrollController.animateTo(
                    0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao enviar: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(children: [
        SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(
                bottom: 100), // Espaço extra para o teclado
            // padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                HeaderWidget(),
                ...secoes.entries.expand((entry) {
                  final secao = entry.key;
                  final perguntas = entry.value;
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    pergunta,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 4),
                        child: Text(
                          'Nome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(181, 228, 136, 74),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _nomeController,
                        focusNode: _nomeFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Digite seu nome',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 4),
                        child: Text(
                          'Comentário',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(181, 228, 136, 74),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _commentsController,
                        focusNode: _commentsFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Deixe seu comentário aqui...',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 5,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 4),
                        child: Text(
                          'CPF',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(181, 228, 136, 74),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _cpfController,
                        focusNode: _cpfFocusNode,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CpfOuCnpjFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Digite seu cpf',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 4),
                        child: Text(
                          'Celular',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(181, 228, 136, 74),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        inputFormatters: [maskFormatter],
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Digite seu celular',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 4),
                        child: Text(
                          'Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(181, 228, 136, 74),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Digite seu email',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(181, 228, 136, 74),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            )),
        SizedBox(
          height: 60,
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          height: 60,
          child: ElevatedButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();

              try {
                await enviarAvaliacaoParaFirestore();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('Avaliação enviada com sucesso!')),
                // );

                // Limpa todos os campos
                _limparFormulario();

                // Rola para o topo
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao enviar: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 228, 136, 74),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Enviar',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        SizedBox(
          height: 30,
        ),
      ]),
    );
  }
}
