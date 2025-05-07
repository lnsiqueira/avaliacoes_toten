import 'package:avaliacao_toten/models/filial_model.dart';
import 'package:avaliacao_toten/pages/avaliar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GestureDetector(
          onTap: () {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          },
          child: const MyHomePage(title: 'Selecionar Filial')),
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
  FilialModel? filialModel;

  @override
  void initState() {
    super.initState();
    verificarSharedPrefs();
  }

  Future<void> verificarSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final codEmpresa = prefs.getString('codEmpresa');

    if (codEmpresa != null) {
      filialModel = FilialModel(
        id: prefs.getString('id') ?? '',
        apelido: prefs.getString('apelido') ?? '',
        codEmpresa: codEmpresa,
        filial: prefs.getString('filial') ?? '',
        passwordApiBratter: prefs.getString('passwordApiBratter') ?? '',
        urlApiBratter: prefs.getString('urlApiBratter') ?? '',
        userApiBratter: prefs.getString('userApiBratter') ?? '',
      );
      setState(() {
        filialSelecionada = true;
        isLoading = false;
      });
    } else {
      final snapshot =
          await FirebaseFirestore.instance.collection('Filial').get();
      filiais = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> salvarFilial(Map<String, dynamic> filial) async {
    final prefs = await SharedPreferences.getInstance();
    filialModel = FilialModel.fromMap(filial);
    for (var entry in filialModel!.toPrefsMap().entries) {
      await prefs.setString(entry.key, entry.value);
    }
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

    if (filialSelecionada && filialModel != null) {
      return PaginaAvaliacao(model: filialModel!);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: DropdownButton<String>(
          hint: const Text("Selecione a filial"),
          value: selectedFilialId,
          onChanged: (String? newValue) {
            setState(() {
              selectedFilialId = newValue;
            });
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
