class RegisterModel {
  String? fotoProfil;
  String namaLengkap;
  String noWhatsapp;
  String email;
  String password;
  bool setujuSyarat;
  String kedudukan; // ceo, manager, admin, cashier, warehouse, employee

  RegisterModel({
    this.fotoProfil,
    this.namaLengkap = '',
    this.noWhatsapp = '',
    this.email = '',
    this.password = '',
    this.setujuSyarat = false,
    this.kedudukan = 'ceo',
  });

  Map<String, String> toMap() {
    return {
      'name': namaLengkap,
      'email': email,
      'password': password,
      'phone': noWhatsapp,
      'role': kedudukan,
    };
  }
}
