class FilialModel {
  final String apelido;
  final String codEmpresa;
  final String filial;
  final String passwordApiBratter;
  final String urlApiBratter;
  final String userApiBratter;

  FilialModel({
    required this.apelido,
    required this.codEmpresa,
    required this.filial,
    required this.passwordApiBratter,
    required this.urlApiBratter,
    required this.userApiBratter,
  });

  factory FilialModel.fromMap(Map<String, dynamic> map) {
    return FilialModel(
      apelido: map['apelido'],
      codEmpresa: map['codEmpresa'],
      filial: map['filial'],
      passwordApiBratter: map['passwordApiBratter'],
      urlApiBratter: map['urlApiBratter'],
      userApiBratter: map['userApiBratter'],
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
