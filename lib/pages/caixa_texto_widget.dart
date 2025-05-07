import 'package:flutter/material.dart';

class CustomerInfoForm extends StatefulWidget {
  const CustomerInfoForm({super.key});

  @override
  State<CustomerInfoForm> createState() => _CustomerInfoFormState();
}

class _CustomerInfoFormState extends State<CustomerInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nome:'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Digite seu nome completo',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('E-mail:'),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Digite seu e-mail',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu e-mail';
              }
              if (!value.contains('@')) {
                return 'E-mail inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('Profissão:'),
          TextFormField(
            controller: _professionController,
            decoration: const InputDecoration(
              hintText: 'Digite sua profissão',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Comentários (opcional):'),
          TextFormField(
            controller: _commentsController,
            decoration: const InputDecoration(
              hintText: 'Deixe seu comentário aqui...',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 40, horizontal: 12),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  debugPrint('Nome: ${_nameController.text}');
                  debugPrint('E-mail: ${_emailController.text}');
                  debugPrint('Profissão: ${_professionController.text}');
                  debugPrint('Comentários: ${_commentsController.text}');
                }
              },
              child: const Text('Enviar'),
            ),
          ),
        ],
      ),
    );
  }
}
