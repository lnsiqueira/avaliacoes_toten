import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase
      .initializeApp(); // Certifique-se de ter configurado o firebase_options.dart
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filial Selector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Selecionar Filial'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = true;
  bool filialSelecionada = false;
  List<Map<String, dynamic>> filiais = [];
  String? selectedFilialId;

  @override
  void initState() {
    super.initState();
    verificarSharedPrefs();
  }

  Future<void> verificarSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final codEmpresa = prefs.getString('codEmpresa');
    if (codEmpresa != null) {
      // Já está salvo, não precisa mostrar o dropdown
      setState(() {
        filialSelecionada = true;
        isLoading = false;
      });
    } else {
      // Carregar do Firebase
      final snapshot =
          await FirebaseFirestore.instance.collection('Filial').get();
      filiais = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> salvarFilial(Map<String, dynamic> filial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apelido', filial['apelido']);
    await prefs.setString('codEmpresa', filial['codEmpresa']);
    await prefs.setString('filial', filial['filial']);
    await prefs.setString('passwordApiBratter', filial['passwordApiBratter']);
    await prefs.setString('urlApiBratter', filial['urlApiBratter']);
    await prefs.setString('userApiBratter', filial['userApiBratter']);
    setState(() {
      filialSelecionada = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (filialSelecionada) {
      return Scaffold(
        appBar: AppBar(title: const Text('Filial Selecionada')),
        body: const Center(child: Text('Bem-vindo! Filial já configurada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: DropdownButton<String>(
          hint: const Text("Selecione a filial"),
          value: selectedFilialId,
          onChanged: (String? newValue) {
            final filial = filiais.firstWhere((f) => f['id'] == newValue);
            salvarFilial(filial);
          },
          items: filiais.map((f) {
            return DropdownMenuItem<String>(
              value: f['id'],
              child: Text('${f['apelido']} (${f['id']})'),
            );
          }).toList(),
        ),
      ),
    );
  }
}
