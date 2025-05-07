class FilialModel {
  final String apelido;
  final String codEmpresa;
  final String filial;
  final String passwordApiBratter;
  final String urlApiBratter;
  final String userApiBratter;
  final String id;

  FilialModel({
    required this.apelido,
    required this.codEmpresa,
    required this.filial,
    required this.passwordApiBratter,
    required this.urlApiBratter,
    required this.userApiBratter,
    required this.id,
  });

  factory FilialModel.fromMap(Map<String, dynamic> map) {
    return FilialModel(
      apelido: map['apelido'],
      codEmpresa: map['codEmpresa'],
      filial: map['filial'],
      passwordApiBratter: map['passwordApiBratter'],
      urlApiBratter: map['urlApiBratter'],
      userApiBratter: map['userApiBratter'],
      id: map['id'],
    );
  }

  Map<String, String> toPrefsMap() {
    return {
      'apelido': apelido,
      'codEmpresa': codEmpresa,
      'filial': filial,
      'passwordApiBratter': passwordApiBratter,
      'urlApiBratter': urlApiBratter,
      'userApiBratter': userApiBratter,
    };
  }
}
