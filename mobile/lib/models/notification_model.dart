class NotifikasiModel {
  final String id;
  final String tipe;     // stok|transaksi|laporan|sistem|promo
  final String judul;
  final String pesan;
  final DateTime waktu;
  final bool sudahDibaca;
  final bool isUrgent;
  final Map<String, dynamic>? data;

  NotifikasiModel({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.waktu,
    required this.sudahDibaca,
    required this.isUrgent,
    this.data,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'].toString(),
      tipe: json['tipe'] as String? ?? 'sistem',
      judul: json['judul'] as String? ?? '',
      pesan: json['pesan'] as String? ?? '',
      waktu: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      sudahDibaca: json['sudah_dibaca'] == true || json['sudah_dibaca'] == 1,
      isUrgent: json['is_urgent'] == true || json['is_urgent'] == 1,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipe': tipe,
      'judul': judul,
      'pesan': pesan,
      'created_at': waktu.toIso8601String(),
      'sudah_dibaca': sudahDibaca,
      'is_urgent': isUrgent,
      'data': data,
    };
  }
}

class NotifikasiSettingModel {
  final bool stokAlert;
  final bool transaksiAlert;
  final bool laporanAlert;
  final bool sistemAlert;
  final bool promoAlert;
  final int stokLimit;
  final String laporanFrekuensi;

  NotifikasiSettingModel({
    required this.stokAlert,
    required this.transaksiAlert,
    required this.laporanAlert,
    required this.sistemAlert,
    required this.promoAlert,
    required this.stokLimit,
    required this.laporanFrekuensi,
  });

  factory NotifikasiSettingModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiSettingModel(
      stokAlert: json['stok_alert'] == true || json['stok_alert'] == 1,
      transaksiAlert: json['transaksi_alert'] == true || json['transaksi_alert'] == 1,
      laporanAlert: json['laporan_alert'] == true || json['laporan_alert'] == 1,
      sistemAlert: json['sistem_alert'] == true || json['sistem_alert'] == 1,
      promoAlert: json['promo_alert'] == true || json['promo_alert'] == 1,
      stokLimit: json['stok_limit'] as int? ?? 10,
      laporanFrekuensi: json['laporan_frekuensi'] as String? ?? 'mingguan',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stok_alert': stokAlert,
      'transaksi_alert': transaksiAlert,
      'laporan_alert': laporanAlert,
      'sistem_alert': sistemAlert,
      'promo_alert': promoAlert,
      'stok_limit': stokLimit,
      'laporan_frekuensi': laporanFrekuensi,
    };
  }
}
